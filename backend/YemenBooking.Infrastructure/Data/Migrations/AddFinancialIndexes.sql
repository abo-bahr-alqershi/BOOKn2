-- إضافة فهارس لتحسين أداء استعلامات الأرصدة المحاسبية
-- Add indexes to improve financial balance queries performance

-- فهرس مركب للمعاملات المحاسبية
CREATE NONCLUSTERED INDEX IX_FinancialTransactions_BalanceQuery
ON FinancialTransactions (Status, TransactionDate, DebitAccountId, CreditAccountId, Amount)
INCLUDE (Id, TransactionNumber);

-- فهرس للحساب المدين
CREATE NONCLUSTERED INDEX IX_FinancialTransactions_DebitAccount
ON FinancialTransactions (DebitAccountId, Status, TransactionDate)
INCLUDE (Amount);

-- فهرس للحساب الدائن
CREATE NONCLUSTERED INDEX IX_FinancialTransactions_CreditAccount
ON FinancialTransactions (CreditAccountId, Status, TransactionDate)
INCLUDE (Amount);

-- فهرس للحسابات حسب النوع
CREATE NONCLUSTERED INDEX IX_ChartOfAccounts_AccountType
ON ChartOfAccounts (AccountType, IsActive)
INCLUDE (Id, AccountNumber, NameAr, NameEn, Balance, ParentAccountId);

-- فهرس للحسابات الفرعية
CREATE NONCLUSTERED INDEX IX_ChartOfAccounts_ParentAccount
ON ChartOfAccounts (ParentAccountId, IsActive)
INCLUDE (Id, AccountNumber, NameAr, Balance);

-- تحديث الإحصائيات
UPDATE STATISTICS FinancialTransactions;
UPDATE STATISTICS ChartOfAccounts;
