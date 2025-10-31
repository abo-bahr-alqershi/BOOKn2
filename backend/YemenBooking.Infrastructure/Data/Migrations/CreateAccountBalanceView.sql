-- إنشاء View لحساب أرصدة الحسابات بشكل محسن
-- Create View for optimized account balance calculation

CREATE OR ALTER VIEW vw_AccountBalances
AS
WITH AccountTransactions AS (
    -- حساب مجموع المدين لكل حساب
    SELECT 
        DebitAccountId AS AccountId,
        SUM(Amount) AS TotalDebit,
        0 AS TotalCredit
    FROM FinancialTransactions
    WHERE Status = 2 -- Posted
        AND DebitAccountId IS NOT NULL
    GROUP BY DebitAccountId
    
    UNION ALL
    
    -- حساب مجموع الدائن لكل حساب
    SELECT 
        CreditAccountId AS AccountId,
        0 AS TotalDebit,
        SUM(Amount) AS TotalCredit
    FROM FinancialTransactions
    WHERE Status = 2 -- Posted
        AND CreditAccountId IS NOT NULL
    GROUP BY CreditAccountId
)
SELECT 
    acc.Id AS AccountId,
    acc.AccountNumber,
    acc.NameAr,
    acc.NameEn,
    acc.AccountType,
    acc.ParentAccountId,
    acc.IsActive,
    COALESCE(SUM(at.TotalDebit), 0) AS TotalDebit,
    COALESCE(SUM(at.TotalCredit), 0) AS TotalCredit,
    -- حساب الرصيد حسب نوع الحساب
    CASE 
        WHEN acc.AccountType IN (1, 5) -- Assets, Expenses (Normal Debit Balance)
            THEN COALESCE(SUM(at.TotalDebit), 0) - COALESCE(SUM(at.TotalCredit), 0)
        ELSE -- Liabilities, Equity, Revenue (Normal Credit Balance)
            COALESCE(SUM(at.TotalCredit), 0) - COALESCE(SUM(at.TotalDebit), 0)
    END AS Balance,
    GETUTCDATE() AS CalculatedAt
FROM ChartOfAccounts acc
LEFT JOIN AccountTransactions at ON acc.Id = at.AccountId
WHERE acc.IsActive = 1
GROUP BY 
    acc.Id,
    acc.AccountNumber,
    acc.NameAr,
    acc.NameEn,
    acc.AccountType,
    acc.ParentAccountId,
    acc.IsActive;

GO

-- إنشاء Stored Procedure للحصول على الأرصدة بتاريخ معين
CREATE OR ALTER PROCEDURE sp_GetAccountBalancesAtDate
    @AsOfDate DATETIME
AS
BEGIN
    SET NOCOUNT ON;
    
    WITH AccountTransactions AS (
        SELECT 
            DebitAccountId AS AccountId,
            SUM(Amount) AS TotalDebit,
            0 AS TotalCredit
        FROM FinancialTransactions
        WHERE Status = 2 -- Posted
            AND TransactionDate <= @AsOfDate
            AND DebitAccountId IS NOT NULL
        GROUP BY DebitAccountId
        
        UNION ALL
        
        SELECT 
            CreditAccountId AS AccountId,
            0 AS TotalDebit,
            SUM(Amount) AS TotalCredit
        FROM FinancialTransactions
        WHERE Status = 2 -- Posted
            AND TransactionDate <= @AsOfDate
            AND CreditAccountId IS NOT NULL
        GROUP BY CreditAccountId
    )
    SELECT 
        acc.Id AS AccountId,
        CASE 
            WHEN acc.AccountType IN (1, 5) -- Assets, Expenses
                THEN COALESCE(SUM(at.TotalDebit), 0) - COALESCE(SUM(at.TotalCredit), 0)
            ELSE -- Liabilities, Equity, Revenue
                COALESCE(SUM(at.TotalCredit), 0) - COALESCE(SUM(at.TotalDebit), 0)
        END AS Balance
    FROM ChartOfAccounts acc
    LEFT JOIN AccountTransactions at ON acc.Id = at.AccountId
    WHERE acc.IsActive = 1
    GROUP BY acc.Id, acc.AccountType;
END;
GO
