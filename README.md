# AuthVaultix Ruby SDK

![AuthVaultix](https://img.shields.io/badge/AuthVaultix-Ruby-red?style=for-the-badge)
![Platform](https://img.shields.io/badge/Platform-Windows-blue?style=for-the-badge)

A professional Ruby implementation for the [AuthVaultix](https://authvaultix.com) authentication service. Secure your Ruby applications with license keys, hardware ID locking, and encrypted sessions.

## 📁 File Structure

- **`authvaultix.rb`**: The core SDK class containing all API logic and communication.
- **`main.rb`**: A complete example script demonstrating initialization, login, and registration.

---

## 🚀 Quick Start

### 1. Setup API Credentials
Configure your application by providing your credentials from the AuthVaultix dashboard.

```ruby
require './authvaultix.rb'

# Create instance
auth = AuthVaultix.new

# Set credentials
auth.Api(
    "YourAppName",
    "YourOwnerID",
    "YourAppSecret",
    "1.0"
)

# Initialize connection
auth.Init
```

### 2. User Authentication
Perform login or registration using the built-in methods.

```ruby
# Standard Login
auth.Login("username", "password")

# Registration with License Key
auth.Register("username", "password", "LICENSE-KEY")

# Simple License Login
auth.License("LICENSE-KEY")
```

---

## 💎 Features

- **Pure Ruby:** No external gems required. Uses `Net::HTTP` and `JSON` from the standard library.
- **HWID Locking:** Automatically fetches the Windows SID for secure hardware locking.
- **Data Persistence:** User information and subscriptions are stored in the `UserData` hash after login.
- **Error Handling:** Built-in validation and clear error messaging for failed requests.

## 🛠️ API Reference

| Method | Description |
| :--- | :--- |
| `Api(name, ownerid, secret, version)` | Sets your application credentials. |
| `Init` | Initializes the session with the AuthVaultix server. |
| `Login(username, password)` | Authenticates an existing user. |
| `Register(username, password, key)` | Registers a new user with a license key. |
| `License(key)` | Authenticates using only a license key. |
| `print_user_info` | Displays current user details and subscriptions. |

---

## 📋 Requirements

- **Ruby:** Version 2.0 or higher.
- **OS:** Windows (for HWID/SID detection via WMIC).

## ⚖️ Disclaimer
This project is intended for use with the AuthVaultix.com authentication service. Ensure you comply with their Terms of Service.

---
