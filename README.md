# 🔐 CryptoVault

A Flutter application that combines **AES-256 encryption** and **LSB steganography** to securely hide secret messages inside ordinary images.

## What is CryptoVault?

CryptoVault uses two layers of security:

- **Cryptography** — encrypts your text using AES-256-CBC so it becomes unreadable without the key
- **Steganography** — hides the encrypted data inside pixel bits of a normal image

The output looks like a regular photo. No one can tell it contains hidden data.

## Features

- AES-256-CBC encryption
- LSB (Least Significant Bit) steganography
- PBKDF2 key derivation (10,000 iterations) — protects against brute force attacks
- SHA-256 integrity hash — detects if image was tampered
- Save stego image directly to Downloads folder
- Clean dark UI

## Tech Stack

| Package         | Purpose                 |
| --------------- | ----------------------- |
| `encrypt`       | AES-256 encryption      |
| `pointycastle`  | PBKDF2 key derivation   |
| `image`         | LSB pixel manipulation  |
| `crypto`        | SHA-256 hashing         |
| `image_picker`  | Gallery image selection |
| `path_provider` | File storage            |

## How It Works

**Encrypt path:**
Text → AES-256 encrypt → ciphertext → embed in PNG pixels (LSB) → stego image saved

**Decrypt path:**
Stego image → extract LSB bits → ciphertext → AES-256 decrypt → original text

## Concepts Used

| Concept           | Description                                                 |
| ----------------- | ----------------------------------------------------------- |
| AES-256-CBC       | Symmetric encryption standard used by governments and banks |
| PBKDF2            | Derives a strong cryptographic key from a password          |
| LSB Steganography | Hides data in the least significant bit of each RGB pixel   |
| SHA-256           | Cryptographic hash function for integrity verification      |

## Run Locally

```bash
git clone https://github.com/athiraravi001/CryptoVault.git
cd CryptoVault
flutter pub get
flutter run
```
