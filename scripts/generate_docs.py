import os
import json
import requests
from pathlib import Path
import anthropic
import openai
from typing import Dict, List, Any
import yaml
import markdown
from bs4 import BeautifulSoup
import base64

class DocumentationGenerator:
    def __init__(self):
        # Initialize Anthropic client
        try:
            self.anthropic_client = anthropic.Anthropic(
                api_key=os.getenv('ANTHROPIC_API_KEY')
            ) if os.getenv('ANTHROPIC_API_KEY') else None
        except Exception as e:
            print(f"Warning: Failed to initialize Anthropic client: {e}")
            self.anthropic_client = None
        
        # Initialize OpenAI client
        try:
            self.openai_client = openai.OpenAI(
                api_key=os.getenv('OPENAI_API_KEY')
            ) if os.getenv('OPENAI_API_KEY') else None
        except Exception as e:
            print(f"Warning: Failed to initialize OpenAI client: {e}")
            self.openai_client = None
        
        self.confluence_base_url = os.getenv('CONFLUENCE_BASE_URL')
        self.confluence_username = os.getenv('CONFLUENCE_USERNAME')
        self.confluence_token = os.getenv('CONFLUENCE_API_TOKEN')
        self.confluence_space = os.getenv('CONFLUENCE_SPACE_KEY')
        
    def scan_codebase(self) -> Dict[str, Any]:
        """Scan the codebase and extract relevant files"""
        extensions = {'.py', '.js', '.ts', '.go', '.java', '.tf', '.yaml', '.yml', '.md'}
        files_data = {}
        
        for file_path in Path('.').rglob('*'):
            if (file_path.is_file() and 
                file_path.suffix in extensions and
                '.git' not in str(file_path) and
                'node_modules' not in str(file_path) and
                '__pycache__' not in str(file_path)):
                
                try:
                    with open(file_path, 'r', encoding='utf-8') as f:
                        content = f.read()
                        files_data[str(file_path)] = {
                            'content': content,
                            'extension': file_path.suffix,
                            'size': len(content)
                        }
                except Exception as e:
                    print(f"Error reading {file_path}: {e}")
        
        return files_data

    def generate_basic_documentation(self, files_data: Dict[str, Any]) -> str:
        """Generate basic documentation without LLM when API is not available"""
        doc = "# Project Documentation\n\n"
        doc += "*Note: This documentation was generated without LLM analysis due to API configuration issues.*\n\n"
        
        # Overview
        doc += "## Overview\n\n"
        doc += f"This project contains {len(files_data)} files across various technologies.\n\n"
        
        # File structure
        doc += "## File Structure\n\n"
        extensions = {}
        for file_path, file_info in files_data.items():
            ext = file_info['extension']
            if ext not in extensions:
                extensions[ext] = []
            extensions[ext].append(file_path)
        
        for ext, files in extensions.items():
            doc += f"### {ext.upper()} Files\n"
            for file_path in sorted(files):
                doc += f"- `{file_path}`\n"
            doc += "\n"
        
        # Configuration files
        config_files = [f for f in files_data.keys() if any(cfg in f.lower() for cfg in ['config', 'settings', '.env', 'makefile', 'requirements'])]
        if config_files:
            doc += "## Configuration Files\n\n"
            for config_file in config_files:
                doc += f"- `{config_file}`\n"
            doc += "\n"
        
        # Scripts
        script_files = [f for f in files_data.keys() if f.startswith('scripts/')]
        if script_files:
            doc += "## Scripts\n\n"
            for script_file in script_files:
                doc += f"- `{script_file}`\n"
            doc += "\n"
        
        doc += "## Setup Instructions\n\n"
        doc += "1. Clone the repository\n"
        doc += "2. Install dependencies as specified in configuration files\n"
        doc += "3. Configure environment variables as needed\n"
        doc += "4. Run the application or scripts as appropriate\n\n"
        
        doc += "---\n"
        doc += "*For more detailed documentation, please configure API keys for LLM analysis.*\n"
        
        return doc

    def analyze_with_llm(self, files_data: Dict[str, Any]) -> str:
        """Analyze code using LLM and generate documentation"""
        
        # Prepare context for LLM
        context = "# Codebase Analysis\n\n"
        for file_path, file_info in files_data.items():
            if file_info['size'] < 10000:  # Limit file size for context
                context += f"## {file_path}\n```{file_info['extension'][1:]}\n{file_info['content']}\n```\n\n"
        
        prompt = f"""
        Analyze this codebase and generate comprehensive documentation. Focus on:
        
        1. **Architecture Overview**: High-level system architecture and design patterns
        2. **Component Analysis**: Individual components, their responsibilities, and interactions
        3. **API Documentation**: Endpoints, functions, and their parameters
        4. **Configuration**: Environment variables, config files, and deployment settings
        5. **Dependencies**: External libraries and their purposes
        6. **Usage Examples**: How to use the system/components
        7. **Development Guide**: How to contribute, build, test, and deploy
        
        Generate the documentation in Markdown format with clear sections and subsections.
        Make it comprehensive but accessible to developers of all levels.
        
        Codebase to analyze:
        {context[:50000]}  # Limit context size
        """
        
        try:
            if self.anthropic_client:
                response = self.anthropic_client.messages.create(
                    model="claude-3-sonnet-20240229",
                    max_tokens=4000,
                    messages=[{"role": "user", "content": prompt}]
                )
                return response.content[0].text
            elif self.openai_client:
                response = self.openai_client.chat.completions.create(
                    model="gpt-4",
                    messages=[{"role": "user", "content": prompt}],
                    max_tokens=4000
                )
                return response.choices[0].message.content
            else:
                # Generate basic documentation without LLM if no client is available
                basic_docs = self.generate_basic_documentation(files_data)
                return basic_docs
        except Exception as e:
            print(f"Error with LLM analysis: {str(e)}")
            # Fallback to basic documentation
            basic_docs = self.generate_basic_documentation(files_data)
            return basic_docs

    def convert_to_confluence_format(self, markdown_content: str) -> str:
        """Convert Markdown to Confluence storage format"""
        # Convert Markdown to HTML first
        html = markdown.markdown(markdown_content, extensions=['codehilite', 'tables'])
        soup = BeautifulSoup(html, 'html.parser')
        
        # Convert to Confluence storage format
        confluence_content = str(soup)
        
        # Basic Confluence-specific conversions
        confluence_content = confluence_content.replace('<code>', '<ac:structured-macro ac:name="code"><ac:plain-text-body><![CDATA[')
        confluence_content = confluence_content.replace('</code>', ']]></ac:plain-text-body></ac:structured-macro>')
        
        return confluence_content

    def publish_to_confluence(self, title: str, content: str) -> bool:
        """Publish documentation to Confluence"""
        if not all([self.confluence_base_url, self.confluence_username, 
                   self.confluence_token, self.confluence_space]):
            print("Confluence configuration missing. Required environment variables:")
            print(f"- CONFLUENCE_BASE_URL: {'✓' if self.confluence_base_url else '✗'}")
            print(f"- CONFLUENCE_USERNAME: {'✓' if self.confluence_username else '✗'}")
            print(f"- CONFLUENCE_API_TOKEN: {'✓' if self.confluence_token else '✗'}")
            print(f"- CONFLUENCE_SPACE_KEY: {'✓' if self.confluence_space else '✗'}")
            return False
        
        confluence_content = self.convert_to_confluence_format(content)
        
        # Normalize base URL (remove trailing slash if present)
        base_url = self.confluence_base_url.rstrip('/')
        
        # Check if page already exists
        search_url = f"{base_url}/rest/api/content"
        search_params = {
            'title': title,
            'spaceKey': self.confluence_space,
            'expand': 'version'
        }
        
        print(f"Attempting to connect to Confluence at: {search_url}")
        print(f"Space key: {self.confluence_space}")
        print(f"Page title: {title}")
        
        # Test basic connectivity first
        test_url = f"{base_url}/rest/api/space"
        auth = (self.confluence_username, self.confluence_token)
        
        print("🔍 Testing basic Confluence connectivity...")
        try:
            test_response = requests.get(test_url, auth=auth, timeout=30)
            print(f"Basic connectivity test: {test_response.status_code}")
            if test_response.status_code != 200:
                print(f"❌ Cannot connect to Confluence API. Response: {test_response.text[:500]}")
                return False
            else:
                print("✅ Basic Confluence API connectivity successful")
        except requests.exceptions.RequestException as e:
            print(f"❌ Network error testing Confluence: {e}")
            return False
        
        # Test if space exists
        print(f"🔍 Testing if space '{self.confluence_space}' exists...")
        space_test_url = f"{base_url}/rest/api/space/{self.confluence_space}"
        try:
            space_response = requests.get(space_test_url, auth=auth, timeout=30)
            if space_response.status_code == 200:
                print("✅ Space exists and is accessible")
            elif space_response.status_code == 404:
                print(f"❌ Space '{self.confluence_space}' does not exist or is not accessible")
                print("💡 Check your space key configuration")
                return False
            else:
                print(f"⚠️ Space test returned: {space_response.status_code}")
        except requests.exceptions.RequestException as e:
            print(f"⚠️ Error testing space: {e}")
        
        try:
            search_response = requests.get(search_url, params=search_params, auth=auth, timeout=30)
        except requests.exceptions.RequestException as e:
            print(f"Network error connecting to Confluence: {e}")
            return False
        
        if search_response.status_code == 200:
            results = search_response.json().get('results', [])
            
            if results:
                # Update existing page
                page_id = results[0]['id']
                current_version = results[0]['version']['number']
                
                update_data = {
                    'id': page_id,
                    'type': 'page',
                    'title': title,
                    'space': {'key': self.confluence_space},
                    'body': {
                        'storage': {
                            'value': confluence_content,
                            'representation': 'storage'
                        }
                    },
                    'version': {'number': current_version + 1}
                }
                
                update_url = f"{base_url}/rest/api/content/{page_id}"
                response = requests.put(update_url, json=update_data, auth=auth)
            else:
                # Create new page
                create_data = {
                    'type': 'page',
                    'title': title,
                    'space': {'key': self.confluence_space},
                    'body': {
                        'storage': {
                            'value': confluence_content,
                            'representation': 'storage'
                        }
                    }
                }
                
                response = requests.post(search_url, json=create_data, auth=auth)
            
            if response.status_code in [200, 201]:
                print(f"Successfully published '{title}' to Confluence")
                return True
            else:
                print(f"Failed to publish to Confluence: {response.status_code} - {response.text}")
                return False
        else:
            print(f"Failed to search Confluence: {search_response.status_code} - {search_response.text}")
            if search_response.status_code == 404:
                print("❌ 404 Error - This usually means:")
                print("  1. The Confluence base URL is incorrect")
                print("  2. The space key doesn't exist")
                print("  3. The REST API path is wrong")
                print("  4. Your Confluence instance doesn't support this API version")
                print(f"  💡 Tip: Verify your base URL format. It should be like:")
                print(f"     - https://yourcompany.atlassian.net/wiki")
                print(f"     - https://confluence.yourcompany.com")
            elif search_response.status_code == 401:
                print("❌ 401 Error - Authentication failed. Check your username and API token.")
            elif search_response.status_code == 403:
                print("❌ 403 Error - Permission denied. Check if you have access to the space.")
            return False

    def generate_and_publish(self):
        """Main method to generate and publish documentation"""
        print("📚 Starting documentation generation...")
        
        # Scan codebase
        print("🔍 Scanning codebase...")
        files_data = self.scan_codebase()
        print(f"Found {len(files_data)} files to analyze")
        
        # Generate documentation with LLM
        print("🤖 Analyzing code with LLM...")
        documentation = self.analyze_with_llm(files_data)
        
        # Save locally
        with open('generated_docs.md', 'w', encoding='utf-8') as f:
            f.write(documentation)
        print("📝 Documentation saved locally as generated_docs.md")
        
        # Publish to Confluence
        if self.confluence_base_url:
            print("🚀 Publishing to Confluence...")
            repo_name = os.environ.get('GITHUB_REPOSITORY', 'Unknown Repository').split('/')[-1]
            title = f"Documentation - {repo_name}"
            success = self.publish_to_confluence(title, documentation)
            if success:
                print("✅ Documentation successfully published to Confluence!")
            else:
                print("❌ Failed to publish to Confluence")
        else:
            print("ℹ️ Confluence not configured, skipping publication")

if __name__ == "__main__":
    generator = DocumentationGenerator()
    generator.generate_and_publish() 