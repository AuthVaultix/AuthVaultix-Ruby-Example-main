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

# Initialize the client
auth = AuthVaultixClient.new(
    "YourAppName",
    "YourOwnerID",
    "YourAppSecret",
    "1.0"
)

# Initialize connection
auth.init
```

### 2. User Authentication
Perform login or registration using the built-in methods.

```ruby
# Standard Login
auth.login("username", "password")

# Registration with License Key
auth.register("username", "password", "LICENSE-KEY")

# Simple License Login
auth.license_login("LICENSE-KEY")
```

---

## 💎 Features

- **Pure Ruby:** No external gems required. Uses `Net::HTTP` and `JSON` from the standard library.
- **HWID Locking:** Automatically fetches the Windows SID for secure hardware locking.
- **Data Persistence:** User information and subscriptions are stored in the `UserData` hash after login.
- **Error Handling:** Built-in validation and clear error messaging for failed requests.

## 🛠️ API Reference

### Authentication & Session
| Method | Description |
| :--- | :--- |
| `init` | Initializes the secure session with the API. |
| `login(username, password)` | Authenticates the user and binds HWID. |
| `register(username, password, key, email?)` | Creates a new user with a license key. |
| `license_login(license)` | Authenticates directly via license key. |
| `check` | Validates if the current session is still active. |
| `logout` | Invalidates current session and logs out. |

### Account Management
| Method | Description |
| :--- | :--- |
| `upgrade(username, license)` | Upgrades user's account/subscription. |
| `forgot_password(username, email)` | Triggers a password reset email. |
| `change_username(new_username)` | Changes the current user's username. |

### Security & Blacklist
| Method | Description |
| :--- | :--- |
| `ban(reason)` | Bans the currently authenticated user. |
| `check_blacklist` | Checks if the machine HWID is blacklisted. |
| `log(message)` | Sends a log to the AuthVaultix dashboard. |

### Variables & Data
| Method | Description |
| :--- | :--- |
| `get_global_var(varid)` | Fetches a global server-side variable. |
| `get_var(var_name)` | Fetches a user-specific server-side variable. |
| `set_var(var_name, value)` | Sets a user-specific variable. |
| `download(fileid)` | Securely downloads a file (returns decoded data). |

### Communication
| Method | Description |
| :--- | :--- |
| `fetch_online` | Gets a list of currently online users. |
| `chat_send(message, channel)` | Sends a chat message to a specific channel. |
| `chat_fetch(channel)` | Retrieves chat history. |

---

## 📋 Requirements

- **Ruby:** Version 2.0 or higher.
- **OS:** Windows (for HWID/SID detection via WMIC).

## ⚖️ Disclaimer
This project is intended for use with the AuthVaultix.com authentication service. Ensure you comply with their Terms of Service.

---
