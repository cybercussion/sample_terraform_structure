import os
import subprocess
import sys
from pathlib import Path
from utils.aws_profile import find_profile_by_account

def can_use_default_aws_profile():
    try:
      subprocess.run(
        ["aws", "sts", "get-caller-identity"],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        check=True
      )
      return True
    except subprocess.CalledProcessError:
      return False

def ensure_aws_profile(account_folder: str):
  """
  Ensures AWS_PROFILE is set based on:
  1. Existing environment
  2. Valid default profile
  3. Extracted or looked-up account ID

  Skipped entirely if CI=true.
  """

  if os.getenv("CI", "").lower() == "true":
    return  # Skip entirely in CI

  if os.getenv("AWS_PROFILE"):
    return  # Already set

  if can_use_default_aws_profile():
    print("✅ AWS CLI appears to work with your default credentials.")
    return

  print("🔍 AWS_PROFILE not set and default credentials failed. Attempting to find a profile...")

  # Extract account ID from folder name (e.g., nonprod-123456789012)
  account_id = None
  parts = account_folder.split("-")
  for part in parts:
    if part.isdigit() and len(part) == 12:
      account_id = part
      break

  # Fallback: Check for account_id.txt in environments/<account>
  if not account_id:
    account_id_file = Path(__file__).resolve().parent.parent.parent / "environments" / account_folder / "account_id.txt"
    if account_id_file.exists():
      account_id = account_id_file.read_text().strip()
      print(f"📄 Found account ID from account_id.txt: {account_id}")

  if not account_id:
    print("❌ Could not determine account ID from folder name or account_id.txt.")
    sys.exit(1)

  # Lookup and set AWS_PROFILE
  try:
    profile = find_profile_by_account(account_id)
    os.environ["AWS_PROFILE"] = profile
    print(f"✅ AWS_PROFILE set to: {profile}")
  except Exception as e:
    print(f"❌ Error: {e}")
    sys.exit(1)