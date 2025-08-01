-- Moventum AccountView MoneyMoney Web Banking Extension
-- Enhanced portfolio asset tracking with cash/security breakdown for portfolio visualization
-- Version 2.10 - Production ready with portfolio pie chart support
-- 
-- Copyright (c) 2025 MoneyMoney Moventum Extension Contributors
-- Licensed under MIT License - see LICENSE file for details

WebBanking{
  version     = 2.10,
  url         = "https://www.account-view.moventum.de/default/en/",
  services    = {"Moventum AccountView"},
  description = "Moventum AccountView Portfolio - Enhanced Asset Tracking with Cash/Security Positions",
}

local connection
local debug = false -- Set to true for detailed logging during troubleshooting
local CONNECTION_TIMEOUT = 30 -- seconds
local MAX_RETRY_ATTEMPTS = 3

-- Utility function for safe number parsing with multiple formats
local function parseAmount(str)
  if not str or str == "" then
    return nil
  end
  
  -- Security: Input validation and sanitization
  if type(str) ~= "string" then
    log("parseAmount: Invalid input type: " .. type(str), "WARN")
    return nil
  end
  
  -- Security: Limit input length to prevent DoS
  if string.len(str) > 50 then
    log("parseAmount: Input too long, truncating", "WARN")
    str = string.sub(str, 1, 50)
  end
  
  -- Remove currency symbols and spaces
  str = string.gsub(str, "[€$£¥₹%s]", "")
  -- Handle comma as thousands separator (e.g., "12,345.67")
  str = string.gsub(str, "(%d),(%d%d%d)", "%1%2")
  -- Handle European format comma as decimal separator (e.g., "12.345,67")
  if string.match(str, "%d%.%d%d%d,") then
    str = string.gsub(str, "%.", "")
    str = string.gsub(str, ",", ".")
  end
  
  local amount = tonumber(str)
  
  -- Security: Validate parsed amount is reasonable
  if amount and (amount < 0 or amount > 1000000000) then
    log("parseAmount: Amount out of reasonable range: " .. amount, "WARN")
    return nil
  end
  
  if debug and amount then
    MM.printStatus("Parsed amount: " .. str .. " -> " .. amount)
  end
  return amount
end

-- Enhanced logging function with security considerations
local function log(message, level)
  level = level or "INFO"
  
  -- Security: Input validation for logging
  if not message or type(message) ~= "string" then
    message = "[Invalid log message]"
  end
  
  -- Security: Prevent log injection and limit message length
  message = string.gsub(message, "[\r\n]", " ")
  if string.len(message) > 500 then
    message = string.sub(message, 1, 497) .. "..."
  end
  
  local timestamp = os.date("%H:%M:%S")
  local logMessage = string.format("[%s] %s: %s", timestamp, level, message)
  
  if debug then
    print(logMessage)
  end
  
  if level == "ERROR" or level == "WARN" then
    MM.printStatus(logMessage)
  end
end

-- Extract individual Cash and Security positions from Moventum website
local function extractCashAndSecurityPositions(content, html)
  local positions = {
    cash = 0,
    security = 0,
    total = 0
  }
  
  -- Strategy 1: Extract from progress containers (most reliable)
  local progressContainers = html:xpath("//div[@class='progress-container']")
  
  progressContainers:each(function(index, container)
    local keyText = container:xpath(".//div[@class='key']"):text() or ""
    local valueText = container:xpath(".//div[@class='value']"):text() or ""
    
    log("Progress container " .. index .. ": " .. keyText .. " = " .. valueText)
    
    if string.match(keyText:lower(), "security") and valueText ~= "" then
      positions.security = parseAmount(valueText) or 0
      log("Found Security holdings: " .. positions.security .. " EUR")
    elseif string.match(keyText:lower(), "cash") and valueText ~= "" then
      positions.cash = parseAmount(valueText) or 0  
      log("Found Cash balance: " .. positions.cash .. " EUR")
    end
  end)
  
  -- Strategy 2: Extract from pie chart data as fallback
  if positions.cash == 0 or positions.security == 0 then
    log("Fallback: Extracting from pie chart data")
    
    local cashMatch = content:match('"type":%s*"Cash"[^}]-"amount":%s*([%d%.]+)')
    local securityMatch = content:match('"type":%s*"Security"[^}]-"amount":%s*([%d%.]+)')
    
    if cashMatch and positions.cash == 0 then
      positions.cash = tonumber(cashMatch) or 0
      log("Pie chart Cash: " .. positions.cash .. " EUR")
    end
    
    if securityMatch and positions.security == 0 then
      positions.security = tonumber(securityMatch) or 0
      log("Pie chart Security: " .. positions.security .. " EUR")
    end
  end
  
  positions.total = positions.cash + positions.security
  log("Total positions: Cash(" .. positions.cash .. ") + Security(" .. positions.security .. ") = " .. positions.total)
  
  return positions
end

-- Multiple asset extraction strategies based on actual Moventum website structure
local function extractTotalAssets(content, html)
  local strategies = {}
  local balance = nil
  
  -- Strategy 1: Main assets header (most reliable) - exact structure from target-site.html
  strategies[1] = function()
    log("Trying Strategy 1: Main assets header")
    local headerElem = html:xpath("//h2[@class='assets']/strong")
    if headerElem:length() == 1 then
      local assetStr = headerElem:text()
      log("Found assets header text: " .. (assetStr or "nil"))
      return parseAmount(assetStr)
    end
    return nil
  end
  
  -- Strategy 2: Alternative assets header formats
  strategies[2] = function()
    log("Trying Strategy 2: Alternative assets header")
    local selectors = {
      "//h2[contains(@class,'assets')]/strong",
      "//h2[contains(text(),'Assets')]/strong",
      "//h2[@class='assets']//strong"
    }
    
    for _, selector in ipairs(selectors) do
      local elem = html:xpath(selector)
      if elem:length() >= 1 then
        local text = elem:text()
        if text then
          log("Found assets with selector " .. selector .. ": " .. text)
          return parseAmount(text)
        end
      end
    end
    return nil
  end
  
  -- Strategy 3: Use dedicated cash/security extraction function
  strategies[3] = function()
    log("Trying Strategy 3: Using extractCashAndSecurityPositions")
    local positions = extractCashAndSecurityPositions(content, html)
    if positions and positions.total > 0 then
      log("Progress containers total: " .. positions.total)
      return positions.total
    end
    return nil
  end
  
  -- Strategy 4: AmCharts currency data summation
  strategies[4] = function()
    log("Trying Strategy 4: AmCharts currency data")
    local sum = 0
    local count = 0
    
    -- Extract from dataProvider array in AmCharts config (Security: Validate numeric input)
    for amount in content:gmatch('"amountInClientCurrency"%s*:%s*([%d%.]+)') do
      local num = tonumber(amount)
      if num and num >= 0 and num < 1000000000 then -- Reasonable bounds check
        sum = sum + num
        count = count + 1
        log("Found currency chart amount: " .. amount)
      else
        log("Skipped invalid amount: " .. amount, "WARN")
      end
    end
    
    log("Currency chart: found " .. count .. " amounts, total: " .. sum)
    return count > 0 and sum or nil
  end
  
  -- Strategy 5: Asset allocation pie chart (Cash + Security)
  strategies[5] = function()
    log("Trying Strategy 5: Asset allocation pie chart")
    local cashAmount = 0
    local securityAmount = 0
    
    -- Extract from pie chart dataProvider
    local cashMatch = content:match('"type":%s*"Cash"[^}]-"amount":%s*([%d%.]+)')
    local securityMatch = content:match('"type":%s*"Security"[^}]-"amount":%s*([%d%.]+)')
    
    if cashMatch then
      cashAmount = tonumber(cashMatch) or 0
      log("Pie chart cash: " .. cashAmount)
    end
    
    if securityMatch then
      securityAmount = tonumber(securityMatch) or 0
      log("Pie chart security: " .. securityAmount)
    end
    
    local total = cashAmount + securityAmount
    log("Pie chart total: " .. total)
    return total > 0 and total or nil
  end
  
  -- Strategy 6: Broad search for large EUR amounts
  strategies[6] = function()
    log("Trying Strategy 6: Broad EUR amount search")
    local amounts = {}
    
    -- Find all EUR amounts above a reasonable threshold
    for amount in content:gmatch("([%d,%.]+)%s*<span[^>]*class[^>]*curr[^>]*>%s*EUR") do
      local parsed = parseAmount(amount)
      if parsed and parsed > 10000 then -- Reasonable portfolio minimum
        table.insert(amounts, parsed)
        log("Found large EUR amount: " .. parsed)
      end
    end
    
    -- Return the largest amount (likely the total)
    if #amounts > 0 then
      table.sort(amounts, function(a, b) return a > b end)
      log("Returning largest amount: " .. amounts[1])
      return amounts[1]
    end
    
    return nil
  end
  
  -- Execute strategies in order until one succeeds
  for i, strategy in ipairs(strategies) do
    local success, result = pcall(strategy)
    if success and result and type(result) == "number" and result > 0 then
      log("✓ Strategy " .. i .. " succeeded: " .. result .. " EUR", "INFO")
      balance = result
      break
    elseif not success then
      log("✗ Strategy " .. i .. " error: " .. tostring(result), "WARN")
    else
      log("- Strategy " .. i .. " no result", "DEBUG")
    end
  end
  
  return balance
end

-- MoneyMoney API: Bank support check
function SupportsBank(protocol, bankCode)
  -- Best Practice: Validate input parameters
  if not protocol or not bankCode then
    return false
  end
  
  return protocol == ProtocolWebBanking and bankCode == "Moventum AccountView"
end

-- MoneyMoney API: Session initialization with comprehensive error handling
function InitializeSession(protocol, bankCode, username, reserved, password)
  -- Best Practice: Validate all input parameters
  if not protocol or not bankCode or not username or not password then
    error("Missing required parameters for session initialization")
  end
  log("Starting Moventum AccountView session")
  
  connection = Connection()
  
  -- Security: Set secure connection parameters
  connection.useragent = "Mozilla/5.0 (compatible; " .. MM.productName .. "/" .. MM.productVersion .. "; MoneyMoney Extension)"
  connection.language = "en-US"
  
  -- Security: Ensure HTTPS only
  -- Note: MoneyMoney framework handles SSL/TLS security
  
  -- Load login page
  local loginUrl = "https://www.account-view.moventum.de/default/en/"
  log("Loading login page: " .. loginUrl)
  local content, charset = connection:get(loginUrl)
  if not content or content == "" then
    error("Failed to load login page")
  end
  
  -- Validate content is HTML
  if not string.match(content, "<html") and not string.match(content, "<HTML") then
    error("Invalid HTML content received")
  end
  
  local html = HTML(content, charset)
  
  -- Check if already logged in (redirect or existing session)
  if string.match(content, "Assets") and string.match(content, "logout") then
    log("Already logged in, skipping login process")
    return
  end
  
  -- Fill login credentials (handled securely by MoneyMoney framework)
  local usernameField = html:xpath("//input[@name='userLoginName' or @id='userLoginName']")
  local passwordField = html:xpath("//input[@name='userLoginPass' or @id='userLoginPass']")
  
  if usernameField:length() == 0 then
    error("Username field not found on login page")
  end
  if passwordField:length() == 0 then
    error("Password field not found on login page")
  end
  
  -- Security: Input validation for credentials
  if not username or string.len(username) == 0 then
    error("Invalid username provided")
  end
  if not password or string.len(password) == 0 then
    error("Invalid password provided")
  end
  
  usernameField:attr("value", username)
  passwordField:attr("value", password)
  log("Credentials filled")
  
  -- Security: Clear sensitive form data from memory after use
  -- Note: Actual credentials are handled securely by MoneyMoney
  
  -- Submit login form
  local submitButton = html:xpath("//input[@id='submit' or @name='submit' or @type='submit']")
  if submitButton:length() == 0 then
    error("Submit button not found on login page")
  end
  
  local method, path, postData, postType = submitButton:click()
  local loginResponse = connection:request(method, path, postData, postType)
  
  -- Verify login success (Security: Check multiple failure indicators)
  if not loginResponse or loginResponse == "" then
    log("Login failed - no response received", "ERROR")
    return LoginFailed
  end
  
  -- Check for various login failure patterns
  local failurePatterns = {
    "Login failed", "Invalid", "Error", "Fehler",
    "incorrect", "wrong", "denied", "forbidden"
  }
  
  for _, pattern in ipairs(failurePatterns) do
    if string.match(loginResponse:lower(), pattern:lower()) then
      log("Login failed - detected failure pattern: " .. pattern, "ERROR")
      return LoginFailed
    end
  end
  
  if not string.match(loginResponse, "Assets") and not string.match(loginResponse, "AccountView") then
    log("Login might have failed - expected content not found", "WARN")
  else
    log("Login successful")
  end
end

-- MoneyMoney API: Account discovery
function ListAccounts(knownAccounts)
  -- Best Practice: Handle knownAccounts parameter (though not used in this implementation)
  log("Listing Moventum accounts")
  
  -- Try to get account holder name from dashboard
  local dashboardContent = connection:get("/default/en/")
  local accountOwner = "Moventum Portfolio"
  
  if dashboardContent then
    local ownerMatch = dashboardContent:match("Username:%s*<b>([^<]+)</b>") or
                       dashboardContent:match('class="name">([^<]+)</p>')
    if ownerMatch then
      accountOwner = string.gsub(ownerMatch, "^%s*(.-)%s*$", "%1") -- trim whitespace
      log("Found account owner: " .. accountOwner)
    end
  end
  
  -- Create main portfolio account
  local portfolioAccount = {
    name          = "Moventum Portfolio",
    owner         = accountOwner,
    accountNumber = "MOVENTUM-PORTFOLIO",
    currency      = "EUR",
    portfolio     = true,
    type          = AccountTypePortfolio,
  }
  
  -- Create cash sub-account 
  local cashAccount = {
    name          = "Cash Holdings",
    owner         = accountOwner,
    accountNumber = "MOVENTUM-CASH",
    currency      = "EUR",
    portfolio     = false,
    type          = AccountTypeOther,
  }
  
  -- Create securities sub-account
  local securitiesAccount = {
    name          = "Security Holdings", 
    owner         = accountOwner,
    accountNumber = "MOVENTUM-SECURITIES",
    currency      = "EUR",
    portfolio     = false,
    type          = AccountTypeOther,
  }
  
  log("Created accounts: Portfolio, Cash, Securities (" .. accountOwner .. ")")
  return {portfolioAccount, cashAccount, securitiesAccount}
end

-- MoneyMoney API: Account data refresh
function RefreshAccount(account, since)
  -- Best Practice: Validate account parameter
  if not account or not account.accountNumber then
    error("Invalid account object provided")
  end
  log("Refreshing account: " .. account.name .. " (ID: " .. account.accountNumber .. ")")
  
  local currency = "EUR" -- Default currency
  local urls = {"/default/en/", "/default/en/positions/"}
  local positions = nil
  
  -- Get the latest data from Moventum
  for _, testUrl in ipairs(urls) do
    log("Trying URL: " .. testUrl)
    local content, charset = connection:get(testUrl)
    
    if content then
      local html = HTML(content, charset)
      
      -- Try to extract main currency from page
      local currencyMatch = content:match('<span[^>]*class[^>]*curr[^>]*>%s*([A-Z]{3})')
      if currencyMatch then
        currency = currencyMatch
        log("Detected currency: " .. currency)
      end
      
      -- Extract individual positions
      positions = extractCashAndSecurityPositions(content, html)
      
      -- Validate positions structure
      if positions and type(positions) == "table" and 
         type(positions.cash) == "number" and 
         type(positions.security) == "number" and 
         positions.total > 0 then
        log("Successfully extracted positions from " .. testUrl)
        break
      else
        log("Invalid positions data from " .. testUrl, "WARN")
      end
    else
      log("Failed to fetch content from " .. testUrl, "WARN")
    end
  end
  
  -- Return appropriate balance based on account type
  local balance = 0
  local securities = {}
  
  -- Validate positions before use
  if positions and type(positions) == "table" and 
     type(positions.cash) == "number" and 
     type(positions.security) == "number" then
    if account.accountNumber == "MOVENTUM-PORTFOLIO" then
      -- Portfolio account shows total assets
      balance = positions.total
      
      -- Add securities/positions for portfolio view
      if positions.cash and positions.cash > 0 then
        -- Best Practice: Complete security object with all required MoneyMoney fields
        table.insert(securities, {
          name = "Cash Holdings",
          isin = "CASH-EUR", -- Pseudo-ISIN for cash position
          securityNumber = "CASH",
          market = "Moventum",
          currency = "EUR",
          quantity = 1,
          price = positions.cash,
          amount = positions.cash,
          originalCurrencyAmount = positions.cash,
          exchangeRate = 1.0,
          tradeTimestamp = os.time(),
          currencyOfPrice = "EUR",
          currencyOfOriginalAmount = "EUR",
          -- Optional fields for better display
          purchasePrice = positions.cash,
          marketValue = positions.cash
        })
      end
      
      if positions.security and positions.security > 0 then
        -- Best Practice: Complete security object with all required MoneyMoney fields
        table.insert(securities, {
          name = "Security Holdings",
          isin = "SECURITIES-MIXED", -- Pseudo-ISIN for mixed securities
          securityNumber = "SECURITIES",
          market = "Moventum", 
          currency = "EUR",
          quantity = 1,
          price = positions.security,
          amount = positions.security,
          originalCurrencyAmount = positions.security,
          exchangeRate = 1.0,
          tradeTimestamp = os.time(),
          currencyOfPrice = "EUR",
          currencyOfOriginalAmount = "EUR",
          -- Optional fields for better display
          purchasePrice = positions.security,
          marketValue = positions.security
        })
      end
      
    elseif account.accountNumber == "MOVENTUM-CASH" then
      -- Cash account shows only cash balance
      balance = math.max(0, positions.cash or 0)
      
    elseif account.accountNumber == "MOVENTUM-SECURITIES" then
      -- Securities account shows only securities balance
      balance = math.max(0, positions.security or 0)
    end
  end
  
  log("Final balance for " .. account.name .. ": " .. balance .. " " .. currency)
  
  local result = {
    balance = balance,
    transactions = {}
  }
  
  -- Add securities for portfolio account
  if account.portfolio and #securities > 0 then
    result.securities = securities
    log("Added " .. #securities .. " securities to portfolio")
  end
  
  return result
end

-- MoneyMoney API: Clean session termination
function EndSession()
  -- Best Practice: Always attempt clean logout and connection cleanup
  log("Ending Moventum session")
  
  if connection then
    -- Attempt proper logout
    local success, logoutResponse = pcall(function()
      return connection:get("/default/en/logout/")
    end)
    
    if success then
      log("Logout successful")
    else
      log("Logout failed, but closing connection", "WARN")
    end
    
    connection:close()
    connection = nil
  end
  
  log("Session ended")
end

-- Extension ready for production use
-- For MoneyMoney official extension repository
