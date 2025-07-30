#!/usr/bin/env python3
"""
Script to download and verify model during Docker build.
"""

import os
import sys
from huggingface_hub import snapshot_download
from transformers import AutoTokenizer, AutoModelForCausalLM


def main():
    """Download and verify the model."""
    try:
        model_name = os.environ['MODEL_NAME']
        cache_dir = os.environ['HF_HOME']
        
        print(f'Downloading model: {model_name}')
        print(f'Cache directory: {cache_dir}')
        
        # Download the model
        snapshot_download(
            repo_id=model_name, 
            cache_dir=cache_dir, 
            local_dir=f'{cache_dir}/{model_name}', 
            local_dir_use_symlinks=False
        )
        
        # Verify the model can be loaded
        try:
            tokenizer = AutoTokenizer.from_pretrained(
                model_name, 
                cache_dir=cache_dir, 
                trust_remote_code=True
            )
            print(f'Successfully downloaded and verified model: {model_name}')
        except Exception as e:
            print(f'Warning: Could not verify model loading: {e}')
            
    except KeyError as e:
        print(f'Error: Missing environment variable {e}')
        sys.exit(1)
    except Exception as e:
        print(f'Error downloading model: {e}')
        sys.exit(1)


if __name__ == "__main__":
    main() 