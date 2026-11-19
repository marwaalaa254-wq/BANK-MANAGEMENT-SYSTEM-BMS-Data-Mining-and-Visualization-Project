-- ========================================================================
-- BANK DATABASE SCHEMA — SQL Server
-- ========================================================================
-- PROJECT   : Bank Management System
-- CREATED BY: Group 5 (Lab 2)
-- ========================================================================
-- DESCRIPTION:
--   This script creates the full database schema for the Bank Management
--   System. It contains 16 tables covering all core banking operations:
--   branches, employees, customers, accounts, transactions, services,
--   loans, cards, beneficiaries, deposits, and audit logging.
-- ========================================================================
--
-- ╔══════════════════════════════════════════════════════════════════════╗
-- ║                        TABLE OF CONTENTS                             ║
-- ╠══════════════════════════════════════════════════════════════════════╣
-- ║                                                                      ║
-- ║  TABLE  01  →  branches         (Branch locations & info)            ║
-- ║  TABLE  02  →  employees        (Bank staff per branch)              ║
-- ║  TABLE  03  →  customers        (Customer profiles)                  ║
-- ║  TABLE  04  →  account_types    (Savings / Current / Investment)     ║
-- ║  TABLE  05  →  account_statuses (Active / Frozen / Closed)           ║
-- ║  TABLE  06  →  accounts         (Customer bank accounts)             ║
-- ║  TABLE  07  →  transaction_types(Deposit / Withdrawal / Transfer)    ║
-- ║  TABLE  08  →  transactions     (All financial movements)            ║
-- ║  TABLE  09  →  services         (Bank service catalog)               ║
-- ║  TABLE  10  →  customer_services(Service subscriptions)              ║
-- ║  TABLE  11  →  loans            (Loan records)                       ║
-- ║  TABLE  12  →  loan_payments    (Loan repayment history)             ║
-- ║  TABLE  13  →  cards            (Debit & credit cards)               ║
-- ║  TABLE  14  →  beneficiaries    (Saved transfer recipients)          ║
-- ║  TABLE  15  →  deposits         (Fixed/term deposits)                ║
-- ║  TABLE  16  →  audit_log        (Change tracking & audit trail)      ║
-- ╚══════════════════════════════════════════════════════════════════════╝

-- ========================================================================

--CREATE DATABASE Bank_Management_System;

--USE Bank_Management_System;

-- ========================================================================
-- TABLE 01: branches
-- ========================================================================

CREATE TABLE branches (
    branch_id       INT PRIMARY KEY,          
    branch_name     VARCHAR(100) NOT NULL,    
    city            VARCHAR(50)  NOT NULL,    
    region          VARCHAR(50)  NOT NULL,    
    phone           VARCHAR(20),              
    address         VARCHAR(255),            
    manager_id      INT,                      
    opening_date    DATE,                    
    is_active       BIT DEFAULT 1             -- 1 = Open, 0 = Closed / inactive
);


-- ========================================================================
-- TABLE 02: employees
-- ========================================================================

CREATE TABLE employees (
    employee_id     INT IDENTITY(1,1) PRIMARY KEY,  
    first_name      VARCHAR(50)  NOT NULL,           
    last_name       VARCHAR(50)  NOT NULL,          
    email           VARCHAR(100) UNIQUE,             
    phone           VARCHAR(20),                     
    address         VARCHAR(255),                    
    role            VARCHAR(50)  NOT NULL,           
    salary          DECIMAL(10,2),                   
    hire_date       DATE         NOT NULL,           
    branch_id       INT          NOT NULL,           
    is_active       BIT          DEFAULT 1,          -- 1 = Currently employed, 0 = Left / terminated
    FOREIGN KEY (branch_id) REFERENCES branches(branch_id)
);

-- ========================================================================
-- ADDING DELAYED FOREIGN KEYS
-- ========================================================================

ALTER TABLE branches
ADD CONSTRAINT FK_Branches_Manager 
FOREIGN KEY (manager_id) REFERENCES employees(employee_id);

-- ========================================================================
-- TABLE 03: customers
-- ========================================================================

CREATE TABLE customers (
    customer_id     INT PRIMARY KEY,                 
    first_name      VARCHAR(50)  NOT NULL,           
    last_name       VARCHAR(50)  NOT NULL,           
    gender          VARCHAR(10),                     
    birth_date      DATE,                            
    national_id     VARCHAR(20)  UNIQUE,            
    email           VARCHAR(100) UNIQUE,             
    phone           VARCHAR(20),                     
    customer_since  DATE         NOT NULL,           
    branch_id       INT,                             
    is_active       BIT          DEFAULT 1,          -- 1 = Active customer, 0 = Deactivated / closed
    FOREIGN KEY (branch_id) REFERENCES branches(branch_id)
);


-- ========================================================================
-- TABLE 04: account_types
-- ========================================================================

CREATE TABLE account_types (
    type_id         INT IDENTITY(1,1) PRIMARY KEY,  
    type_name       VARCHAR(20) NOT NULL UNIQUE      
);


-- ========================================================================
-- TABLE 05: account_statuses
-- ========================================================================


CREATE TABLE account_statuses (
    status_id       INT IDENTITY(1,1) PRIMARY KEY,  
    status_name     VARCHAR(20) NOT NULL UNIQUE      
);


-- ========================================================================
-- TABLE 06: accounts
-- ========================================================================


CREATE TABLE accounts (
    account_id      INT IDENTITY(1,1) PRIMARY KEY,   
    account_number  VARCHAR(20) NOT NULL UNIQUE,     
    customer_id     INT NOT NULL,                    
    branch_id       INT NOT NULL,                    
    account_type_id INT NOT NULL,                    
    status_id       INT NOT NULL DEFAULT 1,          -- Account status — default: 1 (Active)
    currency        VARCHAR(3)  DEFAULT 'INR',       
    current_balance DECIMAL(12,2) NOT NULL DEFAULT 0,
    opened_date     DATE NOT NULL,                   
    closed_date     DATE NULL,                      
    FOREIGN KEY (customer_id)     REFERENCES customers(customer_id),
    FOREIGN KEY (branch_id)       REFERENCES branches(branch_id),
    FOREIGN KEY (account_type_id) REFERENCES account_types(type_id),
    FOREIGN KEY (status_id)       REFERENCES account_statuses(status_id)
);


-- ========================================================================
-- TABLE 07: transaction_types
-- ========================================================================

CREATE TABLE transaction_types (
    type_id         INT IDENTITY(1,1) PRIMARY KEY,  
    type_name       VARCHAR(30) NOT NULL UNIQUE,     
    impact_type     VARCHAR(10) CHECK (impact_type IN ('Credit', 'Debit'))
                                                     
);


-- ========================================================================
-- TABLE 08: transactions
-- ========================================================================


CREATE TABLE transactions (
    transaction_id      INT PRIMARY KEY,             
    customer_id         INT NOT NULL,               
    account_id          INT NOT NULL,               
    transaction_type_id INT NOT NULL,                
    transaction_amount  DECIMAL(10,2) NOT NULL,      
    total_balance       DECIMAL(12,2) NOT NULL,      
    transaction_date    DATETIME2 NOT NULL,           
    description         VARCHAR(255),               
    employee_id         INT NULL,                    -- Staff who processed it — NULL if self-service/online
    FOREIGN KEY (customer_id)         REFERENCES customers(customer_id),
    FOREIGN KEY (account_id)          REFERENCES accounts(account_id),
    FOREIGN KEY (transaction_type_id) REFERENCES transaction_types(type_id),
    FOREIGN KEY (employee_id)         REFERENCES employees(employee_id)
);


-- ========================================================================
-- TABLE 09: services
-- ========================================================================

CREATE TABLE services (
    service_id      INT IDENTITY(1,1) PRIMARY KEY,  
    service_name    VARCHAR(50) NOT NULL UNIQUE,     
    description     VARCHAR(255),                    
    monthly_fee     DECIMAL(8,2)                     -- Monthly charge (NULL = free service)
);


-- ========================================================================
-- TABLE 10: customer_services
-- ========================================================================

CREATE TABLE customer_services (
    customer_id       INT  NOT NULL,                 
    service_id        INT  NOT NULL,                 
    subscription_date DATE NOT NULL,                 
    is_active         BIT  DEFAULT 1,                -- 1 = Currently active, 0 = Cancelled
    PRIMARY KEY (customer_id, service_id),           
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    FOREIGN KEY (service_id)  REFERENCES services(service_id)
);


-- ========================================================================
-- TABLE 11: loans
-- ========================================================================


CREATE TABLE loans (
    loan_id           INT IDENTITY(1,1) PRIMARY KEY, 
    customer_id       INT          NOT NULL,          
    account_id        INT          NOT NULL,          
    branch_id         INT          NOT NULL,          
    loan_amount       DECIMAL(12,2) NOT NULL,         
    interest_rate     DECIMAL(5,2)  NOT NULL,         
    loan_term_months  INT           NOT NULL,         
    start_date        DATE          NOT NULL,         
    end_date          DATE,                           -- Expected / actual end date (NULL if ongoing)
    status            VARCHAR(20)   DEFAULT 'Active', 
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    FOREIGN KEY (account_id)  REFERENCES accounts(account_id),
    FOREIGN KEY (branch_id)   REFERENCES branches(branch_id)
);


-- ========================================================================
-- TABLE 12: loan_payments
-- ========================================================================


CREATE TABLE loan_payments (
    payment_id        INT IDENTITY(1,1) PRIMARY KEY, 
    loan_id           INT           NOT NULL,         
    payment_date      DATE          NOT NULL,         
    amount_paid       DECIMAL(10,2) NOT NULL,         
    remaining_balance DECIMAL(12,2),                  
    FOREIGN KEY (loan_id) REFERENCES loans(loan_id)
);


-- ========================================================================
-- TABLE 13: cards
-- ========================================================================


CREATE TABLE cards (
    card_id       INT IDENTITY(1,1) PRIMARY KEY,     
    account_id    INT          NOT NULL,              
    card_type     VARCHAR(20)  NOT NULL,              
    card_number   VARCHAR(20)  UNIQUE NOT NULL,       
    expiry_date   DATE         NOT NULL,              
    is_active     BIT          DEFAULT 1,             -- 1 = Active, 0 = Blocked / expired
    credit_limit  DECIMAL(10,2) NULL,                 
    FOREIGN KEY (account_id) REFERENCES accounts(account_id)
);


-- ========================================================================
-- TABLE 14: beneficiaries
-- ========================================================================

CREATE TABLE beneficiaries (
    beneficiary_id   INT IDENTITY(1,1) PRIMARY KEY,  
    customer_id      INT          NOT NULL,           
    beneficiary_name VARCHAR(100) NOT NULL,           
    account_number   VARCHAR(20)  NOT NULL,           
    bank_name        VARCHAR(100),                    
    is_active        BIT DEFAULT 1,                   -- 1 = Saved and active, 0 = Removed
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);


-- ========================================================================
-- TABLE 15: deposits
-- ========================================================================


CREATE TABLE deposits (
    deposit_id     INT IDENTITY(1,1) PRIMARY KEY,    
    customer_id    INT           NOT NULL,            
    account_id     INT           NOT NULL,            
    deposit_amount DECIMAL(12,2) NOT NULL,            
    interest_rate  DECIMAL(5,2),                      
    start_date     DATE          NOT NULL,            
    maturity_date  DATE,                              
    subscribed     VARCHAR(5),                        -- 'yes' = active deposit, 'no' = closed / withdrawn
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    FOREIGN KEY (account_id)  REFERENCES accounts(account_id)
);


-- ========================================================================
-- TABLE 16: audit_log
-- ========================================================================


CREATE TABLE audit_log (
    log_id       INT IDENTITY(1,1) PRIMARY KEY,      
    table_name   VARCHAR(50)  NOT NULL,              
    action_type  VARCHAR(10)  NOT NULL,              
    record_id    INT,                                
    changed_by   INT,                               
    change_date  DATETIME2    DEFAULT GETDATE(),     
    description  VARCHAR(255),                       
    FOREIGN KEY (changed_by) REFERENCES employees(employee_id)
);


CREATE INDEX idx_accounts_customer_id ON accounts(customer_id);
CREATE INDEX idx_transactions_account_id ON transactions(account_id);
CREATE INDEX idx_transactions_customer_id ON transactions(customer_id);
CREATE INDEX idx_transactions_transaction_date ON transactions(transaction_date);
CREATE INDEX idx_accounts_account_type ON accounts(account_type_id);
CREATE INDEX idx_customers_email ON customers(email);
CREATE INDEX idx_customers_phone ON customers(phone);

-- Check 
EXEC sp_helpindex 'accounts';
EXEC sp_helpindex 'transactions';
EXEC sp_helpindex 'customers';



