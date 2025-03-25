#!/usr/bin/env python3

"""
aws_profile.py - Find AWS profile by account ID in your ~/.aws/config

Author: Mark Statkus
Description:
  Multi-Account can require getting your profile to run against the target account.
  This script will help you find the profile name in your AWS config file.

Usage (CLI):
  python terraform/scripts/utils/aws_profile.py <account_id>

Requirements:
  - Python 3.6+
  - terragrunt and terraform in PATH
  - questionary (auto-installed if missing)
"""

import sys
from pathlib import Path

def find_profile_by_account(account_id):
  config_path = Path.home() / ".aws" / "config"
  if not config_path.exists():
    print("❌ AWS config file not found at ~/.aws/config")
    sys.exit(1)

  profile = None
  current_profile = None

  with config_path.open() as f:
    for line in f:
      line = line.strip()
      if line.startswith("[profile "):
        current_profile = line.replace("[profile ", "").replace("]", "").strip()
      elif "sso_account_id" in line and account_id in line:
        profile = current_profile
        break

  if not profile:
    print(f"❌ ERROR: No profile found for sso_account_id: {account_id}")
    sys.exit(1)

  print(profile)

if __name__ == "__main__":
  if len(sys.argv) < 2:
    print(f"Usage: {Path(__file__).name} <sso_account_id>")
    sys.exit(1)

  target_account_id = sys.argv[1]
  find_profile_by_account(target_account_id)