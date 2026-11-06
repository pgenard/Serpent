import re
import sys

INPUT_FILE = "Serpent-128-128.verified.test-vectors"
OUTPUT_FILE = "serpent128_vectors.hex"

with open(INPUT_FILE, "r") as f:
    content = f.read()

# Split the file into individual vector sections.
blocks = re.split(r"(?=Set\s+\d+,\s*vector#)", content)

vectors = []

for block in blocks:

    key_match = re.search(
        r"key\s*=\s*([0-9a-fA-F]+)", block
    )

    plain_match = re.search(
        r"plain\s*=\s*([0-9a-fA-F]+)", block
    )

    cipher_match = re.search(
        r"cipher\s*=\s*([0-9a-fA-F]+)", block
    )

    if not (key_match and plain_match and cipher_match):
        continue

    key = key_match.group(1)
    plaintext = plain_match.group(1)
    ciphertext = cipher_match.group(1)

    # Keep only Serpent-128 encryption vectors.
    if len(key) != 32:
        continue

    if len(plaintext) != 32 or len(ciphertext) != 32:
        continue

    vectors.append((key, plaintext, ciphertext))


with open(OUTPUT_FILE, "w") as f:

    for key, plaintext, ciphertext in vectors:

        f.write(
            f"{key} {plaintext} {ciphertext}\n"
        )

print("SERPENT-128 VECTOR EXTRACTION")
print("--------------------------------")
print("Extracted vectors:", len(vectors))
print("Output file:", OUTPUT_FILE)
print("--------------------------------")
