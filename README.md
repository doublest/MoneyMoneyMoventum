# Moventum AccountView Extension for MoneyMoney

A MoneyMoney web banking extension for Moventum AccountView that provides comprehensive portfolio tracking with detailed cash and security position breakdown.

## Features

- **Complete Portfolio Overview**: Import your total Moventum portfolio value
- **Detailed Position Breakdown**: Separate tracking of cash holdings and security positions
- **Portfolio Visualization**: Enables MoneyMoney's pie chart view showing cash vs. security allocation
- **Multi-Currency Support**: Handles multiple currencies with automatic conversion to EUR base currency
- **Robust Data Extraction**: Multiple fallback strategies ensure reliable balance extraction
- **Enhanced Logging**: Detailed logging for troubleshooting and monitoring

## Supported Accounts

The extension creates three account types in MoneyMoney:

1. **Moventum Portfolio** (Portfolio Account)
   - Shows total assets with pie chart breakdown
   - Displays cash and security positions as separate segments

2. **Cash Holdings** (Cash Account) 
   - Shows liquid cash balance only
   - Direct access to cash position

3. **Security Holdings** (Securities Account)
   - Shows investment/security positions only
   - Direct access to security holdings

## Installation

1. Download the `moventum.lua` file
2. Copy it to your MoneyMoney Extensions folder:
   - **macOS**: `~/Library/Containers/com.moneymoney-app.moneymoney/Data/Library/Application Support/MoneyMoney/Extensions/`
   - **Alternative**: Use MoneyMoney's menu: *Help > Show Extensions Folder*
3. Restart MoneyMoney
4. Add a new account and select "Moventum AccountView" as the bank

## Setup

1. In MoneyMoney, go to *File > Add Account*
2. Search for "Moventum AccountView" 
3. Enter your Moventum AccountView credentials:
   - **Bank Code**: `Moventum AccountView`
   - **Username**: Your AccountView username
   - **Password**: Your AccountView password
4. Complete the setup - three accounts will be created automatically

## Requirements

- MoneyMoney 2.3.0 or later
- Active Moventum AccountView account
- Internet connection for data synchronization

## Data Extraction Methods

The extension uses multiple strategies to ensure reliable data extraction:

1. **Primary Method**: HTML progress containers extraction
2. **Fallback Method**: JavaScript chart data parsing
3. **Currency Detection**: Automatic currency recognition
4. **Error Handling**: Graceful fallback if primary methods fail

## Supported Moventum Features

- ✅ Total portfolio value
- ✅ Cash holdings breakdown
- ✅ Security positions breakdown  
- ✅ Multi-currency portfolios
- ✅ Account holder information
- ⚠️ Individual security details (limited)
- ❌ Transaction history (not available via web interface)

## Privacy & Security

- No data is stored locally beyond MoneyMoney's standard caching
- All communication uses HTTPS encryption
- Credentials are handled securely by MoneyMoney
- No third-party data sharing

## Troubleshooting

### Common Issues

**"Login failed" error:**
- Verify your AccountView credentials are correct
- Ensure your account is not locked
- Check internet connectivity

**"No balance found" error:**
- Your account might be empty or inactive
- Moventum website structure may have changed
- Enable debug logging (see below)

**Multiple currency issues:**
- The extension automatically converts to EUR base currency
- Check MoneyMoney's currency settings

### Debug Logging

To enable detailed logging for troubleshooting:

1. Open `moventum.lua` in a text editor
2. Find the line: `local debug = true`
3. Ensure it's set to `true`
4. Restart MoneyMoney and check the log output

## Contributing

Contributions are welcome! Please feel free to submit issues, feature requests, or pull requests.

### Development Setup

1. Clone this repository
2. Edit `moventum.lua` with your changes
3. Test with MoneyMoney in development mode
4. Submit a pull request

## Version History

### v2.10 (Current)
- Added separate cash and security position tracking
- Implemented portfolio visualization support
- Enhanced multi-currency handling
- Improved error handling and logging

### v2.00 
- Complete rewrite with robust data extraction
- Multiple fallback strategies
- Enhanced error handling

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Disclaimer

This extension is not officially affiliated with Moventum S.C.A. or MoneyMoney. Use at your own risk. The authors are not responsible for any financial data discrepancies or account issues.

## Support Moventum

If this extension is helpful, consider:
- ⭐ Starring this repository
- 🐛 Reporting bugs or issues
- 💡 Suggesting new features
- 🔧 Contributing improvements

---

**Note**: This extension requires an active Moventum AccountView account. Visit [Moventum AccountView](https://www.account-view.moventum.de/) for more information about their services.