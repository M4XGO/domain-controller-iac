#!/usr/bin/env python3
"""
Auto Documentation Generator

This script analyzes a codebase using LLM and generates comprehensive documentation,
then optionally publishes it to Confluence.
"""

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
import argparse
import logging

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


class DocumentationGenerator:
    """Main class for generating documentation from codebase"""
    
    def __init__(self):
        """Initialize the documentation generator with API clients"""
        self.anthropic_client = anthropic.Anthropic(
            api_key=os.getenv('ANTHROPIC_API_KEY')
        ) if os.getenv('ANTHROPIC_API_KEY') else None
        
        self.openai_client = openai.OpenAI(
            api_key=os.getenv('OPENAI_API_KEY')
        ) if os.getenv('OPENAI_API_KEY') else None
        
        self.confluence_base_url = os.getenv('CONFLUENCE_BASE_URL')
        self.confluence_username = os.getenv('CONFLUENCE_USERNAME')
        self.confluence_token = os.getenv('CONFLUENCE_API_TOKEN')
        self.confluence_space = os.getenv('CONFLUENCE_SPACE_KEY')
        
        # Validate at least one LLM client is available
        if not self.anthropic_client and not self.openai_client:
            logger.warning("No LLM API key configured. Documentation generation will be limited.")
    
    def scan_codebase(self, base_path: str = '.') -> Dict[str, Any]:
        """
        Scan the codebase and extract relevant files
        
        Args:
            base_path: Root path to scan from
            
        Returns:
            Dictionary containing file data
        """
        logger.info(f"Scanning codebase from: {base_path}")
        
        # File extensions to analyze
        extensions = {'.py', '.js', '.ts', '.go', '.java', '.tf', '.yaml', '.yml', '.md', '.json'}
        
        # Directories to exclude
        exclude_dirs = {'.git', 'node_modules', '__pycache__', '.pytest_cache', 
                       'venv', '.venv', 'env', '.env', 'dist', 'build', '.terraform'}
        
        files_data = {}
        base_path_obj = Path(base_path)
        
        for file_path in base_path_obj.rglob('*'):
            if (file_path.is_file() and 
                file_path.suffix in extensions and
                not any(excluded in file_path.parts for excluded in exclude_dirs)):
                
                try:
                    with open(file_path, 'r', encoding='utf-8') as f:
                        content = f.read()
                        relative_path = file_path.relative_to(base_path_obj)
                        files_data[str(relative_path)] = {
                            'content': content,
                            'extension': file_path.suffix,
                            'size': len(content),
                            'lines': len(content.splitlines())
                        }
                except Exception as e:
                    logger.warning(f"Error reading {file_path}: {e}")
        
        logger.info(f"Found {len(files_data)} files to analyze")
        return files_data
    
    def create_analysis_prompt(self, files_data: Dict[str, Any]) -> str:
        """
        Create the prompt for LLM analysis
        
        Args:
            files_data: Dictionary containing file information
            
        Returns:
            Formatted prompt string
        """
        # Prepare context for LLM (limit size to avoid token limits)
        context = "# Codebase Analysis\n\n"
        total_size = 0
        max_context_size = 40000  # Limit context size
        
        # Sort files by importance (smaller files first, then by extension)
        sorted_files = sorted(
            files_data.items(),
            key=lambda x: (x[1]['size'], x[1]['extension'], x[0])
        )
        
        for file_path, file_info in sorted_files:
            if total_size + file_info['size'] > max_context_size:
                break
                
            if file_info['size'] < 15000:  # Only include reasonably sized files
                ext = file_info['extension'][1:] if file_info['extension'] else 'text'
                context += f"## {file_path}\n```{ext}\n{file_info['content']}\n```\n\n"
                total_size += file_info['size']
        
        prompt = f"""
Analyze this codebase and generate comprehensive documentation in French. Focus on:

1. **Vue d'ensemble de l'architecture**: Architecture système de haut niveau et patterns de conception
2. **Analyse des composants**: Composants individuels, leurs responsabilités et interactions
3. **Documentation des APIs**: Endpoints, fonctions et leurs paramètres
4. **Configuration**: Variables d'environnement, fichiers de config et paramètres de déploiement
5. **Dépendances**: Bibliothèques externes et leur utilisation
6. **Exemples d'utilisation**: Comment utiliser le système/composants
7. **Guide de développement**: Comment contribuer, construire, tester et déployer

Generate the documentation in Markdown format with clear sections and subsections.
Make it comprehensive but accessible to developers of all levels.
Use French for all text except code comments and technical terms.

Codebase to analyze:
{context}

Please provide a well-structured documentation that would help new developers understand and contribute to this project.
"""
        
        return prompt
    
    def analyze_with_llm(self, files_data: Dict[str, Any]) -> str:
        """
        Analyze code using LLM and generate documentation
        
        Args:
            files_data: Dictionary containing file information
            
        Returns:
            Generated documentation as markdown string
        """
        logger.info("Analyzing code with LLM...")
        
        prompt = self.create_analysis_prompt(files_data)
        
        try:
            if self.anthropic_client:
                logger.info("Using Anthropic Claude for analysis")
                response = self.anthropic_client.messages.create(
                    model="claude-3-sonnet-20240229",
                    max_tokens=4000,
                    messages=[{"role": "user", "content": prompt}]
                )
                return response.content[0].text
                
            elif self.openai_client:
                logger.info("Using OpenAI GPT for analysis")
                response = self.openai_client.chat.completions.create(
                    model="gpt-4",
                    messages=[{"role": "user", "content": prompt}],
                    max_tokens=4000
                )
                return response.choices[0].message.content
                
            else:
                error_msg = "Error: No LLM API key configured"
                logger.error(error_msg)
                return error_msg
                
        except Exception as e:
            error_msg = f"Error generating documentation: {str(e)}"
            logger.error(error_msg)
            return error_msg
    
    def convert_to_confluence_format(self, markdown_content: str) -> str:
        """
        Convert Markdown to Confluence storage format
        
        Args:
            markdown_content: Documentation in markdown format
            
        Returns:
            Content formatted for Confluence
        """
        logger.info("Converting documentation to Confluence format")
        
        # Convert Markdown to HTML first
        html = markdown.markdown(
            markdown_content, 
            extensions=['codehilite', 'tables', 'fenced_code']
        )
        soup = BeautifulSoup(html, 'html.parser')
        
        # Convert to Confluence storage format
        confluence_content = str(soup)
        
        # Basic Confluence-specific conversions
        confluence_content = confluence_content.replace(
            '<code>', 
            '<ac:structured-macro ac:name="code"><ac:plain-text-body><![CDATA['
        )
        confluence_content = confluence_content.replace(
            '</code>', 
            ']]></ac:plain-text-body></ac:structured-macro>'
        )
        
        # Convert code blocks
        confluence_content = confluence_content.replace(
            '<pre><code>',
            '<ac:structured-macro ac:name="code"><ac:plain-text-body><![CDATA['
        )
        confluence_content = confluence_content.replace(
            '</code></pre>',
            ']]></ac:plain-text-body></ac:structured-macro>'
        )
        
        return confluence_content
    
    def publish_to_confluence(self, title: str, content: str) -> bool:
        """
        Publish documentation to Confluence
        
        Args:
            title: Page title
            content: Page content in markdown format
            
        Returns:
            True if successful, False otherwise
        """
        if not all([self.confluence_base_url, self.confluence_username, 
                   self.confluence_token, self.confluence_space]):
            logger.warning("Confluence configuration missing")
            return False
        
        logger.info(f"Publishing '{title}' to Confluence...")
        
        confluence_content = self.convert_to_confluence_format(content)
        
        # Check if page already exists
        search_url = f"{self.confluence_base_url}/rest/api/content"
        search_params = {
            'title': title,
            'spaceKey': self.confluence_space,
            'expand': 'version'
        }
        
        auth = (self.confluence_username, self.confluence_token)
        
        try:
            search_response = requests.get(search_url, params=search_params, auth=auth)
            search_response.raise_for_status()
            
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
                
                update_url = f"{self.confluence_base_url}/rest/api/content/{page_id}"
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
            
            response.raise_for_status()
            
            if response.status_code in [200, 201]:
                logger.info(f"Successfully published '{title}' to Confluence")
                return True
            else:
                logger.error(f"Failed to publish to Confluence: {response.status_code} - {response.text}")
                return False
                
        except requests.exceptions.RequestException as e:
            logger.error(f"Network error publishing to Confluence: {e}")
            return False
        except Exception as e:
            logger.error(f"Error publishing to Confluence: {e}")
            return False
    
    def save_local_documentation(self, content: str, filename: str = 'generated_docs.md') -> None:
        """
        Save documentation locally
        
        Args:
            content: Documentation content
            filename: Output filename
        """
        try:
            with open(filename, 'w', encoding='utf-8') as f:
                f.write(content)
            logger.info(f"Documentation saved locally as {filename}")
        except Exception as e:
            logger.error(f"Error saving documentation locally: {e}")
    
    def generate_and_publish(self, base_path: str = '.', output_file: str = 'generated_docs.md') -> bool:
        """
        Main method to generate and publish documentation
        
        Args:
            base_path: Root path to scan
            output_file: Output filename for local documentation
            
        Returns:
            True if successful, False otherwise
        """
        logger.info("🚀 Starting documentation generation...")
        
        try:
            # Scan codebase
            logger.info("🔍 Scanning codebase...")
            files_data = self.scan_codebase(base_path)
            
            if not files_data:
                logger.warning("No files found to analyze")
                return False
            
            # Generate documentation with LLM
            logger.info("🤖 Analyzing code with LLM...")
            documentation = self.analyze_with_llm(files_data)
            
            if "Error:" in documentation:
                logger.error("Failed to generate documentation")
                return False
            
            # Save locally
            self.save_local_documentation(documentation, output_file)
            
            # Publish to Confluence if configured
            if self.confluence_base_url:
                logger.info("🚀 Publishing to Confluence...")
                repo_name = os.environ.get('GITHUB_REPOSITORY', 'Unknown Repository').split('/')[-1]
                title = f"Documentation - {repo_name}"
                success = self.publish_to_confluence(title, documentation)
                
                if success:
                    logger.info("✅ Documentation successfully published to Confluence!")
                else:
                    logger.warning("❌ Failed to publish to Confluence")
                    
            else:
                logger.info("ℹ️ Confluence not configured, skipping publication")
            
            logger.info("✅ Documentation generation completed successfully!")
            return True
            
        except Exception as e:
            logger.error(f"Error in documentation generation: {e}")
            return False


def main():
    """Main entry point"""
    parser = argparse.ArgumentParser(description='Generate documentation from codebase using LLM')
    parser.add_argument('--path', default='.', help='Path to scan (default: current directory)')
    parser.add_argument('--output', default='generated_docs.md', help='Output filename')
    parser.add_argument('--verbose', '-v', action='store_true', help='Enable verbose logging')
    
    args = parser.parse_args()
    
    if args.verbose:
        logging.getLogger().setLevel(logging.DEBUG)
    
    generator = DocumentationGenerator()
    success = generator.generate_and_publish(args.path, args.output)
    
    exit(0 if success else 1)


if __name__ == "__main__":
    main() 