import os
import subprocess
import sys
from pathlib import Path
from utils.aws_profile import find_profile_by_account

def can_use_default_aws_profile(account_id: str) -> bool:
  try:
    result = subprocess.run(
      ["aws", "sts", "get-caller-identity", "--output", "json"],
      check=True,
      stdout=subprocess.PIPE,
      stderr=subprocess.DEVNULL,
      text=True
    )
    import json
    identity = json.loads(result.stdout)
    return identity.get("Account") == account_id
  except Exception:
      return False
    
def get_account_id_from_profile(profile_name: str) -> str:
    try:
        result = subprocess.run(
            ["aws", "sts", "get-caller-identity", "--profile", profile_name, "--output", "json"],
            check=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            text=True
        )
        import json
        return json.loads(result.stdout).get("Account")
    except Exception:
        return None

def ensure_aws_profile(account_folder: str):
  if os.getenv("CI", "").lower() == "true":
    return

  if os.getenv("AWS_PROFILE"):
    return

  # Step 1: Try to extract an account_id
  account_id = None
  parts = account_folder.split("-")
  for part in parts:
    if part.isdigit() and len(part) == 12:
      account_id = part
      break

  account_id_file = Path(__file__).resolve().parent.parent.parent / "environments" / account_folder / "account_id.txt"
  if not account_id and account_id_file.exists():
    account_id = account_id_file.read_text().strip()
    print(f"📄 Found account ID from account_id.txt: {account_id}")

  # Step 2: If no account ID, just try using default creds and hope for the best
  if not account_id:
    default_cred_account_id = get_account_id_from_profile('default') 
    print(f"⚠️  No account ID found in path or account_id.txt.")
    print(f"ℹ️  Using default AWS credentials, which appear to belong to account: {default_cred_account_id}")
    return

  # Step 3: Check if default creds match the expected account
  if can_use_default_aws_profile(account_id):
    print("✅ Default AWS credentials are valid for this account.")
    return

  # Step 4: Try to find a matching profile
  print("🔍 Default credentials failed. Attempting to find a matching profile...")
  try:
    profile = find_profile_by_account(account_id)
    os.environ["AWS_PROFILE"] = profile
    print(f"✅ AWS_PROFILE set to: {profile}")
  except Exception as e:
    print(f"❌ Error: {e}")
    sys.exit(1)