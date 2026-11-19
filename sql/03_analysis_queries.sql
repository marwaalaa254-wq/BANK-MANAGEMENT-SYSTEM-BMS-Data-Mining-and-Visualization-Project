/*Q1) Customer Master View
Create a view vw_CustomerMaster that returns:
 CustomerID, FullName, NationalID, Phone, Email, City
 TotalAccounts (count)
 TotalBalance (sum of balances across accounts)
Then query Top 20 customers by TotalBalance.*/
CREATE VIEW vw_CustomerMaster AS 
SELECT c.customer_id AS CustomerID,
    c.first_name + ' ' + c.last_name AS FullName,
    c.national_id AS NationalID,
    c.phone AS Phone,
    c.email AS Email,
    b.city AS City,
    COUNT(a.account_id)AS TotalAccounts,
    ISNULL(SUM(a.current_balance), 0) AS TotalBalance
FROM customers c
LEFT JOIN branches b  ON c.branch_id  = b.branch_id
LEFT JOIN accounts a  ON c.customer_id = a.customer_id
GROUP BY c.customer_id,c.first_name,c.last_name,c.national_id,c.phone,c.email, b.city;
SELECT TOP 20 *
FROM vw_CustomerMaster
ORDER BY TotalBalance DESC;

--========================================================================================
/*Q2) Account Portfolio View (Status + Branch)
Create a view vw_AccountPortfolio showing:
 AccountNo, CustomerName, BranchName, AccountType, OpenedOn, Status,
Balance
Then write a query to list all inactive/closed accounts ordered by OpenedOn
DESC.*/
CREATE VIEW vw_AccountPortfolio AS
SELECT
    a.account_number AS AccountNo,
    c.first_name + ' ' + c.last_name     AS CustomerName,
    b.branch_name AS BranchName,
    at.type_name AS AccountType,
    a.opened_date AS OpenedOn,
    ast.status_name AS Status,
    a.current_balance AS Balance
FROM accounts a JOIN customers c ON a.customer_id= c.customer_id
JOIN branches b ON a.branch_id = b.branch_id
JOIN account_types at ON a.account_type_id = at.type_id
JOIN account_statuses ast ON a.status_id  = ast.status_id;
SELECT *
FROM vw_AccountPortfolio
WHERE Status IN ('Frozen', 'Closed')
ORDER BY OpenedOn DESC;
--=========================================================================
/*Q3) Monthly Transaction Summary (Credits/Debits/Net)
Write a SQL query that returns per month (last 12 months):
 YearMonth
 TotalCreditAmount
 TotalDebitAmount
 NetFlow = Credit − Debit
 TransactionsCount*/
SELECT FORMAT(t.transaction_date, 'yyyy-MM')AS YearMonth,
    SUM(CASE WHEN tt.impact_type = 'Credit' 
             THEN t.transaction_amount ELSE 0 END)AS TotalCreditAmount,
    SUM(CASE WHEN tt.impact_type = 'Debit'  
             THEN t.transaction_amount ELSE 0 END)AS TotalDebitAmount,
    SUM(CASE WHEN tt.impact_type = 'Credit' 
             THEN t.transaction_amount ELSE 0 END) -
    SUM(CASE WHEN tt.impact_type = 'Debit'  
             THEN t.transaction_amount ELSE 0 END)AS NetFlow,
    COUNT(t.transaction_id) AS TransactionsCount
FROM transactions t
JOIN transaction_types tt ON t.transaction_type_id = tt.type_id
WHERE t.transaction_date >= DATEADD(MONTH, -12, GETDATE())
GROUP BY FORMAT(t.transaction_date, 'yyyy-MM')
ORDER BY YearMonth;
--============================================================================
/*Q4) Customer Statement View (Transaction History)
Create a view vw_CustomerStatement that returns:
 CustomerID, CustomerName, AccountNo
 TxnDateTime, TxnType, Amount, Description
Then query the statement for a given CustomerID and date range.
*/
CREATE VIEW vw_CustomerStatement AS
SELECT
    c.customer_id AS CustomerID,
    c.first_name + ' ' + c.last_name  AS CustomerName,
    a.account_number AS AccountNo,
    t.transaction_date AS TxnDateTime,
    tt.type_name AS TxnType,
    t.transaction_amount AS Amount,
    t.description AS Description
FROM transactions t
JOIN customers c  ON t.customer_id   = c.customer_id
JOIN accounts  a  ON t.account_id  = a.account_id
JOIN transaction_types tt ON t.transaction_type_id  = tt.type_id;
SELECT *
FROM vw_CustomerStatement
WHERE CustomerID   = 1001
  AND TxnDateTime >= '2024-01-01'
  AND TxnDateTime <  '2025-01-01'
ORDER BY TxnDateTime DESC;
--========================================================================
/*Q5) Top Customers by Activity (Ranking)
Write a query to return the Top 10 customers by:
 number of transactions in last 90 days
Also show: TotalCredit, TotalDebit, NetFlow.
(Bonus: use ROW_NUMBER() / DENSE_RANK() if supported.)*/
SELECT TOP 10
    c.customer_id AS CustomerID,
    c.first_name + ' ' + c.last_name AS CustomerName,
    COUNT(t.transaction_id) AS TransactionsCount,
    SUM(CASE WHEN tt.impact_type = 'Credit'THEN t.transaction_amount ELSE 0 END) AS TotalCredit,
    SUM(CASE WHEN tt.impact_type = 'Debit' THEN t.transaction_amount ELSE 0 END)AS TotalDebit,
    SUM(CASE WHEN tt.impact_type = 'Credit'THEN t.transaction_amount ELSE 0 END) -
    SUM(CASE WHEN tt.impact_type = 'Debit'THEN t.transaction_amount ELSE 0 END) AS NetFlow,
    ROW_NUMBER() OVER ( ORDER BY COUNT(t.transaction_id) DESC) AS RowNum,
    DENSE_RANK() OVER (ORDER BY COUNT(t.transaction_id) DESC)AS ActivityRank
FROM transactions t
JOIN customers c  ON t.customer_id = c.customer_id
JOIN transaction_types tt ON t.transaction_type_id  = tt.type_id
WHERE t.transaction_date >= DATEADD(DAY, -90, GETDATE())
GROUP BY c.customer_id, c.first_name,c.last_name
ORDER BY TransactionsCount DESC;
--========================================
/*Q6) Branch Performance View
Create a view vw_BranchPerformance (last 30 days) with:
 BranchName
 CustomersCount (distinct customers with accounts in branch)
 TransactionsCount
 TotalTransactionValue (credit + debit)
 NetFlow
Then query branches ordered by NetFlow DESC*/
CREATE VIEW vw_BranchPerformance AS
SELECT
    b.branch_name AS BranchName,
    COUNT(DISTINCT a.customer_id) AS CustomersCount,
    COUNT(t.transaction_id)AS TransactionsCount,
    SUM(t.transaction_amount)AS TotalTransactionValue,
    SUM(CASE WHEN tt.impact_type = 'Credit'THEN t.transaction_amount ELSE 0 END) -
    SUM(CASE WHEN tt.impact_type = 'Debit'THEN t.transaction_amount ELSE 0 END) AS NetFlow
FROM branches b
JOIN accounts a  ON b.branch_id= a.branch_id
JOIN transactions  t  ON a.account_id= t.account_id
JOIN transaction_types tt ON t.transaction_type_id = tt.type_id
WHERE t.transaction_date >= DATEADD(DAY, -30, GETDATE())
GROUP BY b.branch_name;
SELECT *
FROM vw_BranchPerformance
ORDER BY NetFlow DESC;

/*Q7) Employee Activity Report
Write a query that returns Top 10 employees by transactions handled (last 30 days):
 EmployeeName, Role, BranchName
 TransactionsHandled, TotalValueHandled*/
SELECT TOP 10
    e.first_name + ' ' + e.last_name AS EmployeeName,
    e.role AS Role,
    b.branch_name AS BranchName,
    COUNT(t.transaction_id) AS TransactionsHandled,
    SUM(t.transaction_amount) AS TotalValueHandled
FROM employees e
JOIN branches  b  ON e.branch_id= b.branch_id
JOIN transactions t  ON e.employee_id= t.employee_id
WHERE t.transaction_date >= DATEADD(DAY, -30, GETDATE())
GROUP BY
    e.employee_id,
    e.first_name,
    e.last_name,
    e.role,
    b.branch_name
ORDER BY TransactionsHandled DESC;
--=======================================================
/*Q8) Service Adoption & Cross-Sell View
Create a view vw_ServiceAdoption showing:
 CustomerID, CustomerName
 ActiveServicesCount
 List/summary of services (or service names in rows)
Then write a query to list customers with 2 or more active services*/
CREATE VIEW vw_ServiceAdoption AS
SELECT
    c.customer_id AS CustomerID,
    c.first_name + ' ' + c.last_name AS CustomerName,
    COUNT(cs.service_id)AS ActiveServicesCount,
    STRING_AGG(s.service_name, ', ') AS ServiceNames
FROM customers c
JOIN customer_services cs  ON c.customer_id  = cs.customer_id
JOIN services s   ON cs.service_id  = s.service_id
WHERE cs.is_active = 1
GROUP BY c.customer_id, c.first_name,c.last_name;
SELECT *
FROM vw_ServiceAdoption
WHERE ActiveServicesCount >= 2
ORDER BY ActiveServicesCount DESC;
--========================================================================
/*Q9) Inactive Accounts (Risk / Operations)
Write a query that lists accounts with no transactions in the last 60 days:
 AccountNo, CustomerName, BranchName, Balance
 LastTxnDate, DaysSinceLastTxn
Order by DaysSinceLastTxn DESC.*/
SELECT
    a.account_number AS AccountNo,
    c.first_name + ' ' + c.last_name AS CustomerName,
    b.branch_name AS BranchName,
    a.current_balance AS Balance,
    MAX(t.transaction_date) AS LastTxnDate,
    DATEDIFF(DAY, MAX(t.transaction_date), GETDATE()) AS DaysSinceLastTxn
FROM accounts a
JOIN customers c  ON a.customer_id = c.customer_id
JOIN branches  b  ON a.branch_id   = b.branch_id
LEFT JOIN transactions t ON a.account_id = t.account_id
GROUP BY a.account_id,a.account_number, c.first_name, c.last_name, b.branch_name,a.current_balance
HAVING MAX(t.transaction_date) < DATEADD(DAY, -60, GETDATE()) OR MAX(t.transaction_date) IS NULL
ORDER BY DaysSinceLastTxn DESC;
--=============================================================================================================
/*Q10) Suspicious Transaction Detection (Rule-Based)
Write a query to flag suspicious transactions, for example:
 transactions greater than (AVG(amount) + 3×STDDEV(amount)) per branch
OR
 debit transactions that exceed 80% of account balance at the time (if balance
stored)
Return:
 TxnID, AccountNo, CustomerName, BranchName, TxnType, Amount,
TxnDateTime, FlagReason*/
WITH BranchStats AS (
    SELECT  b.branch_id, AVG(t.transaction_amount) AS AvgAmount, STDEV(t.transaction_amount) AS StdAmount
    FROM transactions t JOIN accounts a  ON t.account_id = a.account_id JOIN branches b ON a.branch_id = b.branch_id
    GROUP BY b.branch_id),
TransactionDetails AS (SELECT t.transaction_id,
        t.transaction_amount,
        t.transaction_date,
        t.total_balance,
        t.description,
        a.account_number,
        a.branch_id,
        c.first_name + ' ' + c.last_name AS CustomerName,
        b.branch_name AS BranchName,
        tt.type_name AS TxnType,
        tt.impact_type
    FROM transactions t
    JOIN accounts a  ON t.account_id = a.account_id
    JOIN customers  c  ON t.customer_id  = c.customer_id
    JOIN branches  b  ON a.branch_id = b.branch_id
    JOIN transaction_types tt ON t.transaction_type_id = tt.type_id)
SELECT
    td.transaction_id AS TxnID,
    td.account_number AS AccountNo,
    td.CustomerName,
    td.BranchName,
    td.TxnType,
    td.transaction_amount AS Amount,
    td.transaction_date AS TxnDateTime,
    CASE
        WHEN td.transaction_amount > (bs.AvgAmount + 3 * bs.StdAmount)
        THEN 'Amount exceeds AVG + 3x STDEV for branch'
        WHEN td.impact_type = 'Debit'
         AND td.total_balance > 0  AND td.transaction_amount > (td.total_balance * 0.80)
        THEN 'Debit exceeds 80% of account balance'
    END AS FlagReason
FROM TransactionDetails td
JOIN BranchStats bs ON td.branch_id = bs.branch_id
WHERE td.transaction_amount > (bs.AvgAmount + 3 * bs.StdAmount)OR (td.impact_type = 'Debit' AND td.total_balance > 0
        AND td.transaction_amount > (td.total_balance * 0.80) )ORDER BY td.transaction_date DESC;