using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using YemenBooking.Core.Entities;
using YemenBooking.Infrastructure.Data.Context;

namespace YemenBooking.Infrastructure.Seeds;

/// <summary>
/// بذر الحسابات الأساسية في دليل الحسابات
/// Seed basic accounts in Chart of Accounts
/// </summary>
public static class ChartOfAccountSeeder
{
    /// <summary>
    /// تنفيذ بذر الحسابات الأساسية
    /// Execute seeding of basic accounts
    /// </summary>
    public static async Task SeedAsync(YemenBookingDbContext context, ILogger logger)
    {
        try
        {
            logger.LogInformation("بدء بذر الحسابات الأساسية في دليل الحسابات");

            // التحقق من وجود حسابات في قاعدة البيانات
            if (await context.ChartOfAccounts.AnyAsync())
            {
                logger.LogInformation("دليل الحسابات يحتوي على بيانات بالفعل، تخطي البذر");
                return;
            }

            var accounts = new List<ChartOfAccount>();

            // ==================== 1. الأصول (Assets) ====================
            
            // الأصول الرئيسية
            var assets = new ChartOfAccount
            {
                Id = Guid.NewGuid(),
                AccountNumber = "1000",
                NameAr = "الأصول",
                NameEn = "Assets",
                AccountType = AccountType.Assets,
                Category = AccountCategory.Main,
                NormalBalance = AccountNature.Debit,
                Level = 1,
                Description = "جميع أصول الشركة",
                IsActive = true,
                IsSystemAccount = true,
                CanPost = false,
                CreatedAt = DateTime.UtcNow
            };
            accounts.Add(assets);

            // الأصول المتداولة
            var currentAssets = new ChartOfAccount
            {
                Id = Guid.NewGuid(),
                AccountNumber = "1100",
                NameAr = "الأصول المتداولة",
                NameEn = "Current Assets",
                AccountType = AccountType.Assets,
                Category = AccountCategory.Sub,
                ParentAccountId = assets.Id,
                NormalBalance = AccountNature.Debit,
                Level = 2,
                Description = "الأصول قصيرة الأجل",
                IsActive = true,
                IsSystemAccount = true,
                CanPost = false,
                CreatedAt = DateTime.UtcNow
            };
            accounts.Add(currentAssets);

            // حسابات انتقالية
            var transitAccounts = new ChartOfAccount
            {
                Id = Guid.NewGuid(),
                AccountNumber = "1900",
                NameAr = "حسابات انتقالية",
                NameEn = "Transit Accounts",
                AccountType = AccountType.Assets,
                Category = AccountCategory.Sub,
                ParentAccountId = assets.Id,
                NormalBalance = AccountNature.Debit,
                Level = 2,
                Description = "حسابات مؤقتة للعمليات قيد المعالجة",
                IsActive = true,
                IsSystemAccount = true,
                CanPost = false,
                CreatedAt = DateTime.UtcNow
            };
            accounts.Add(transitAccounts);

            // المدفوعات قيد المعالجة
            accounts.Add(new ChartOfAccount
            {
                Id = Guid.NewGuid(),
                AccountNumber = "1901",
                NameAr = "المدفوعات قيد المعالجة",
                NameEn = "Payments in Processing",
                AccountType = AccountType.Assets,
                Category = AccountCategory.Sub,
                ParentAccountId = transitAccounts.Id,
                NormalBalance = AccountNature.Debit,
                Level = 3,
                Description = "المدفوعات في انتظار التأكيد",
                IsActive = true,
                IsSystemAccount = true,
                CanPost = true,
                CreatedAt = DateTime.UtcNow
            });

            // النقدية
            accounts.Add(new ChartOfAccount
            {
                Id = Guid.NewGuid(),
                AccountNumber = "1101",
                NameAr = "النقدية",
                NameEn = "Cash",
                AccountType = AccountType.Assets,
                Category = AccountCategory.Sub,
                ParentAccountId = currentAssets.Id,
                NormalBalance = AccountNature.Debit,
                Level = 3,
                Description = "النقد في الصندوق",
                IsActive = true,
                IsSystemAccount = true,
                CanPost = true,
                CreatedAt = DateTime.UtcNow
            });

            // البنك
            accounts.Add(new ChartOfAccount
            {
                Id = Guid.NewGuid(),
                AccountNumber = "1102",
                NameAr = "البنك",
                NameEn = "Bank",
                AccountType = AccountType.Assets,
                Category = AccountCategory.Sub,
                ParentAccountId = currentAssets.Id,
                NormalBalance = AccountNature.Debit,
                Level = 3,
                Description = "الأرصدة البنكية",
                IsActive = true,
                IsSystemAccount = true,
                CanPost = true,
                CreatedAt = DateTime.UtcNow
            });

            // المحافظ الإلكترونية
            accounts.Add(new ChartOfAccount
            {
                Id = Guid.NewGuid(),
                AccountNumber = "1103",
                NameAr = "المحافظ الإلكترونية",
                NameEn = "E-Wallets",
                AccountType = AccountType.Assets,
                Category = AccountCategory.Sub,
                ParentAccountId = currentAssets.Id,
                NormalBalance = AccountNature.Debit,
                Level = 3,
                Description = "أرصدة المحافظ الإلكترونية",
                IsActive = true,
                IsSystemAccount = true,
                CanPost = true,
                CreatedAt = DateTime.UtcNow
            });

            // ذمم مدينة - عملاء
            accounts.Add(new ChartOfAccount
            {
                Id = Guid.NewGuid(),
                AccountNumber = "1110",
                NameAr = "ذمم مدينة - عملاء",
                NameEn = "Accounts Receivable - Customers",
                AccountType = AccountType.Assets,
                Category = AccountCategory.Sub,
                ParentAccountId = currentAssets.Id,
                NormalBalance = AccountNature.Debit,
                Level = 3,
                Description = "المبالغ المستحقة من العملاء",
                IsActive = true,
                IsSystemAccount = true,
                CanPost = true,
                CreatedAt = DateTime.UtcNow
            });

            // الدفعات المقدمة من العملاء
            accounts.Add(new ChartOfAccount
            {
                Id = Guid.NewGuid(),
                AccountNumber = "1111",
                NameAr = "الدفعات المقدمة من العملاء",
                NameEn = "Customer Advances",
                AccountType = AccountType.Assets,
                Category = AccountCategory.Sub,
                ParentAccountId = currentAssets.Id,
                NormalBalance = AccountNature.Debit,
                Level = 3,
                Description = "المبالغ المدفوعة مقدماً من العملاء",
                IsActive = true,
                IsSystemAccount = true,
                CanPost = true,
                CreatedAt = DateTime.UtcNow
            });

            // حسابات النزلاء الجارية
            accounts.Add(new ChartOfAccount
            {
                Id = Guid.NewGuid(),
                AccountNumber = "1112",
                NameAr = "حسابات النزلاء الجارية",
                NameEn = "Guest Current Accounts",
                AccountType = AccountType.Assets,
                Category = AccountCategory.Sub,
                ParentAccountId = currentAssets.Id,
                NormalBalance = AccountNature.Debit,
                Level = 3,
                Description = "حسابات النزلاء أثناء الإقامة",
                IsActive = true,
                IsSystemAccount = true,
                CanPost = true,
                CreatedAt = DateTime.UtcNow
            });

            // ==================== 2. الالتزامات (Liabilities) ====================
            
            // الالتزامات الرئيسية
            var liabilities = new ChartOfAccount
            {
                Id = Guid.NewGuid(),
                AccountNumber = "2000",
                NameAr = "الالتزامات",
                NameEn = "Liabilities",
                AccountType = AccountType.Liabilities,
                Category = AccountCategory.Main,
                NormalBalance = AccountNature.Credit,
                Level = 1,
                Description = "جميع التزامات الشركة",
                IsActive = true,
                IsSystemAccount = true,
                CanPost = false,
                CreatedAt = DateTime.UtcNow
            };
            accounts.Add(liabilities);

            // الالتزامات المتداولة
            var currentLiabilities = new ChartOfAccount
            {
                Id = Guid.NewGuid(),
                AccountNumber = "2100",
                NameAr = "الالتزامات المتداولة",
                NameEn = "Current Liabilities",
                AccountType = AccountType.Liabilities,
                Category = AccountCategory.Sub,
                ParentAccountId = liabilities.Id,
                NormalBalance = AccountNature.Credit,
                Level = 2,
                Description = "الالتزامات قصيرة الأجل",
                IsActive = true,
                IsSystemAccount = true,
                CanPost = false,
                CreatedAt = DateTime.UtcNow
            };
            accounts.Add(currentLiabilities);

            // ذمم دائنة - ملاك
            accounts.Add(new ChartOfAccount
            {
                Id = Guid.NewGuid(),
                AccountNumber = "2101",
                NameAr = "ذمم دائنة - ملاك",
                NameEn = "Accounts Payable - Owners",
                AccountType = AccountType.Liabilities,
                Category = AccountCategory.Sub,
                ParentAccountId = currentLiabilities.Id,
                NormalBalance = AccountNature.Credit,
                Level = 3,
                Description = "المبالغ المستحقة للملاك",
                IsActive = true,
                IsSystemAccount = true,
                CanPost = true,
                CreatedAt = DateTime.UtcNow
            });

            // الضرائب المستحقة
            accounts.Add(new ChartOfAccount
            {
                Id = Guid.NewGuid(),
                AccountNumber = "2110",
                NameAr = "الضرائب المستحقة",
                NameEn = "Taxes Payable",
                AccountType = AccountType.Liabilities,
                Category = AccountCategory.Sub,
                ParentAccountId = currentLiabilities.Id,
                NormalBalance = AccountNature.Credit,
                Level = 3,
                Description = "الضرائب المستحقة الدفع",
                IsActive = true,
                IsSystemAccount = true,
                CanPost = true,
                CreatedAt = DateTime.UtcNow
            });

            // أموال الملاك المعلقة
            accounts.Add(new ChartOfAccount
            {
                Id = Guid.NewGuid(),
                AccountNumber = "2105",
                NameAr = "أموال الملاك المعلقة",
                NameEn = "Owners' Funds Pending",
                AccountType = AccountType.Liabilities,
                Category = AccountCategory.Sub,
                ParentAccountId = currentLiabilities.Id,
                NormalBalance = AccountNature.Credit,
                Level = 3,
                Description = "المبالغ المحصلة للملاك في انتظار التحويل",
                IsActive = true,
                IsSystemAccount = true,
                CanPost = true,
                CreatedAt = DateTime.UtcNow
            });

            // عمولات المنصة المستحقة
            accounts.Add(new ChartOfAccount
            {
                Id = Guid.NewGuid(),
                AccountNumber = "2107",
                NameAr = "عمولات المنصة المستحقة",
                NameEn = "Platform Commissions Payable",
                AccountType = AccountType.Liabilities,
                Category = AccountCategory.Sub,
                ParentAccountId = currentLiabilities.Id,
                NormalBalance = AccountNature.Credit,
                Level = 3,
                Description = "عمولات المنصة المستحقة على الحجوزات والخدمات",
                IsActive = true,
                IsSystemAccount = true,
                CanPost = true,
                CreatedAt = DateTime.UtcNow
            });

            // حساب الأمانات
            accounts.Add(new ChartOfAccount
            {
                Id = Guid.NewGuid(),
                AccountNumber = "2106",
                NameAr = "حساب الأمانات",
                NameEn = "Trust Account",
                AccountType = AccountType.Liabilities,
                Category = AccountCategory.Sub,
                ParentAccountId = currentLiabilities.Id,
                NormalBalance = AccountNature.Credit,
                Level = 3,
                Description = "أموال العملاء المحتفظ بها كأمانة",
                IsActive = true,
                IsSystemAccount = true,
                CanPost = true,
                CreatedAt = DateTime.UtcNow
            });

            // ودائع الضمان
            accounts.Add(new ChartOfAccount
            {
                Id = Guid.NewGuid(),
                AccountNumber = "2120",
                NameAr = "ودائع الضمان",
                NameEn = "Security Deposits",
                AccountType = AccountType.Liabilities,
                Category = AccountCategory.Sub,
                ParentAccountId = currentLiabilities.Id,
                NormalBalance = AccountNature.Credit,
                Level = 3,
                Description = "ودائع الضمان المستلمة من العملاء",
                IsActive = true,
                IsSystemAccount = true,
                CanPost = true,
                CreatedAt = DateTime.UtcNow
            });

            // الإيرادات المؤجلة
            accounts.Add(new ChartOfAccount
            {
                Id = Guid.NewGuid(),
                AccountNumber = "2130",
                NameAr = "الإيرادات المؤجلة",
                NameEn = "Deferred Revenue",
                AccountType = AccountType.Liabilities,
                Category = AccountCategory.Sub,
                ParentAccountId = currentLiabilities.Id,
                NormalBalance = AccountNature.Credit,
                Level = 3,
                Description = "إيرادات محصلة مقدماً لخدمات لم تقدم بعد",
                IsActive = true,
                IsSystemAccount = true,
                CanPost = true,
                CreatedAt = DateTime.UtcNow
            });

            // الإيرادات المستحقة
            accounts.Add(new ChartOfAccount
            {
                Id = Guid.NewGuid(),
                AccountNumber = "2140",
                NameAr = "الإيرادات المستحقة",
                NameEn = "Accrued Revenue",
                AccountType = AccountType.Liabilities,
                Category = AccountCategory.Sub,
                ParentAccountId = currentLiabilities.Id,
                NormalBalance = AccountNature.Credit,
                Level = 3,
                Description = "إيرادات مستحقة لم تحصل بعد",
                IsActive = true,
                IsSystemAccount = true,
                CanPost = true,
                CreatedAt = DateTime.UtcNow
            });

            // العمولات المستحقة للوكلاء
            accounts.Add(new ChartOfAccount
            {
                Id = Guid.NewGuid(),
                AccountNumber = "2150",
                NameAr = "العمولات المستحقة للوكلاء",
                NameEn = "Agent Commissions Payable",
                AccountType = AccountType.Liabilities,
                Category = AccountCategory.Sub,
                ParentAccountId = currentLiabilities.Id,
                NormalBalance = AccountNature.Credit,
                Level = 3,
                Description = "عمولات مستحقة للوكلاء والوسطاء",
                IsActive = true,
                IsSystemAccount = true,
                CanPost = true,
                CreatedAt = DateTime.UtcNow
            });

            // ==================== 3. حقوق الملكية (Equity) ====================
            
            // حقوق الملكية الرئيسية
            var equity = new ChartOfAccount
            {
                Id = Guid.NewGuid(),
                AccountNumber = "3000",
                NameAr = "حقوق الملكية",
                NameEn = "Equity",
                AccountType = AccountType.Equity,
                Category = AccountCategory.Main,
                NormalBalance = AccountNature.Credit,
                Level = 1,
                Description = "حقوق ملكية الشركة",
                IsActive = true,
                IsSystemAccount = true,
                CanPost = false,
                CreatedAt = DateTime.UtcNow
            };
            accounts.Add(equity);

            // حساب المنصة
            accounts.Add(new ChartOfAccount
            {
                Id = Guid.NewGuid(),
                AccountNumber = "3100",
                NameAr = "حساب المنصة",
                NameEn = "Platform Account",
                AccountType = AccountType.Equity,
                Category = AccountCategory.Sub,
                ParentAccountId = equity.Id,
                NormalBalance = AccountNature.Credit,
                Level = 2,
                Description = "حساب أرباح المنصة",
                IsActive = true,
                IsSystemAccount = true,
                CanPost = true,
                CreatedAt = DateTime.UtcNow
            });

            // الأرباح المحتجزة
            accounts.Add(new ChartOfAccount
            {
                Id = Guid.NewGuid(),
                AccountNumber = "3200",
                NameAr = "الأرباح المحتجزة",
                NameEn = "Retained Earnings",
                AccountType = AccountType.Equity,
                Category = AccountCategory.Sub,
                ParentAccountId = equity.Id,
                NormalBalance = AccountNature.Credit,
                Level = 2,
                Description = "الأرباح المحتجزة",
                IsActive = true,
                IsSystemAccount = true,
                CanPost = true,
                CreatedAt = DateTime.UtcNow
            });

            // ==================== 4. الإيرادات (Revenue) ====================
            
            // الإيرادات الرئيسية
            var revenue = new ChartOfAccount
            {
                Id = Guid.NewGuid(),
                AccountNumber = "4000",
                NameAr = "الإيرادات",
                NameEn = "Revenue",
                AccountType = AccountType.Revenue,
                Category = AccountCategory.Main,
                NormalBalance = AccountNature.Credit,
                Level = 1,
                Description = "جميع إيرادات الشركة",
                IsActive = true,
                IsSystemAccount = true,
                CanPost = false,
                CreatedAt = DateTime.UtcNow
            };
            accounts.Add(revenue);

            // الإيرادات التشغيلية
            var operatingRevenue = new ChartOfAccount
            {
                Id = Guid.NewGuid(),
                AccountNumber = "4100",
                NameAr = "الإيرادات التشغيلية",
                NameEn = "Operating Revenue",
                AccountType = AccountType.Revenue,
                Category = AccountCategory.Sub,
                ParentAccountId = revenue.Id,
                NormalBalance = AccountNature.Credit,
                Level = 2,
                Description = "الإيرادات من العمليات الأساسية",
                IsActive = true,
                IsSystemAccount = true,
                CanPost = false,
                CreatedAt = DateTime.UtcNow
            };
            accounts.Add(operatingRevenue);

            // إيرادات الحجوزات
            accounts.Add(new ChartOfAccount
            {
                Id = Guid.NewGuid(),
                AccountNumber = "4101",
                NameAr = "إيرادات الحجوزات",
                NameEn = "Booking Revenue",
                AccountType = AccountType.Revenue,
                Category = AccountCategory.Sub,
                ParentAccountId = operatingRevenue.Id,
                NormalBalance = AccountNature.Credit,
                Level = 3,
                Description = "الإيرادات من حجوزات العقارات",
                IsActive = true,
                IsSystemAccount = true,
                CanPost = true,
                CreatedAt = DateTime.UtcNow
            });

            // عمولات المنصة
            accounts.Add(new ChartOfAccount
            {
                Id = Guid.NewGuid(),
                AccountNumber = "4110",
                NameAr = "عمولات المنصة",
                NameEn = "Platform Commissions",
                AccountType = AccountType.Revenue,
                Category = AccountCategory.Sub,
                ParentAccountId = operatingRevenue.Id,
                NormalBalance = AccountNature.Credit,
                Level = 3,
                Description = "عمولات المنصة على الحجوزات",
                IsActive = true,
                IsSystemAccount = true,
                CanPost = true,
                CreatedAt = DateTime.UtcNow
            });

            // إيرادات الحجوزات المؤكدة
            accounts.Add(new ChartOfAccount
            {
                Id = Guid.NewGuid(),
                AccountNumber = "4102",
                NameAr = "إيرادات الحجوزات المؤكدة",
                NameEn = "Confirmed Booking Revenue",
                AccountType = AccountType.Revenue,
                Category = AccountCategory.Sub,
                ParentAccountId = operatingRevenue.Id,
                NormalBalance = AccountNature.Credit,
                Level = 3,
                Description = "إيرادات الحجوزات المؤكدة",
                IsActive = true,
                IsSystemAccount = true,
                CanPost = true,
                CreatedAt = DateTime.UtcNow
            });

            // إيرادات الحجوزات المحققة
            accounts.Add(new ChartOfAccount
            {
                Id = Guid.NewGuid(),
                AccountNumber = "4103",
                NameAr = "إيرادات الحجوزات المحققة",
                NameEn = "Realized Booking Revenue",
                AccountType = AccountType.Revenue,
                Category = AccountCategory.Sub,
                ParentAccountId = operatingRevenue.Id,
                NormalBalance = AccountNature.Credit,
                Level = 3,
                Description = "إيرادات الحجوزات المحققة بعد تسجيل الدخول",
                IsActive = true,
                IsSystemAccount = true,
                CanPost = true,
                CreatedAt = DateTime.UtcNow
            });

            // رسوم الخدمات
            accounts.Add(new ChartOfAccount
            {
                Id = Guid.NewGuid(),
                AccountNumber = "4120",
                NameAr = "رسوم الخدمات",
                NameEn = "Service Fees",
                AccountType = AccountType.Revenue,
                Category = AccountCategory.Sub,
                ParentAccountId = operatingRevenue.Id,
                NormalBalance = AccountNature.Credit,
                Level = 3,
                Description = "رسوم الخدمات الإضافية",
                IsActive = true,
                IsSystemAccount = true,
                CanPost = true,
                CreatedAt = DateTime.UtcNow
            });

            // رسوم الإلغاء
            accounts.Add(new ChartOfAccount
            {
                Id = Guid.NewGuid(),
                AccountNumber = "4130",
                NameAr = "رسوم الإلغاء",
                NameEn = "Cancellation Fees",
                AccountType = AccountType.Revenue,
                Category = AccountCategory.Sub,
                ParentAccountId = operatingRevenue.Id,
                NormalBalance = AccountNature.Credit,
                Level = 3,
                Description = "رسوم إلغاء الحجوزات",
                IsActive = true,
                IsSystemAccount = true,
                CanPost = true,
                CreatedAt = DateTime.UtcNow
            });

            // رسوم التأخير
            accounts.Add(new ChartOfAccount
            {
                Id = Guid.NewGuid(),
                AccountNumber = "4140",
                NameAr = "رسوم التأخير",
                NameEn = "Late Fees",
                AccountType = AccountType.Revenue,
                Category = AccountCategory.Sub,
                ParentAccountId = operatingRevenue.Id,
                NormalBalance = AccountNature.Credit,
                Level = 3,
                Description = "رسوم التأخير في تسجيل الخروج",
                IsActive = true,
                IsSystemAccount = true,
                CanPost = true,
                CreatedAt = DateTime.UtcNow
            });

            // ==================== 5. المصروفات (Expenses) ====================
            
            // المصروفات الرئيسية
            var expenses = new ChartOfAccount
            {
                Id = Guid.NewGuid(),
                AccountNumber = "5000",
                NameAr = "المصروفات",
                NameEn = "Expenses",
                AccountType = AccountType.Expenses,
                Category = AccountCategory.Main,
                NormalBalance = AccountNature.Debit,
                Level = 1,
                Description = "جميع مصروفات الشركة",
                IsActive = true,
                IsSystemAccount = true,
                CanPost = false,
                CreatedAt = DateTime.UtcNow
            };
            accounts.Add(expenses);

            // المصروفات التشغيلية
            var operatingExpenses = new ChartOfAccount
            {
                Id = Guid.NewGuid(),
                AccountNumber = "5100",
                NameAr = "المصروفات التشغيلية",
                NameEn = "Operating Expenses",
                AccountType = AccountType.Expenses,
                Category = AccountCategory.Sub,
                ParentAccountId = expenses.Id,
                NormalBalance = AccountNature.Debit,
                Level = 2,
                Description = "مصروفات العمليات الأساسية",
                IsActive = true,
                IsSystemAccount = true,
                CanPost = false,
                CreatedAt = DateTime.UtcNow
            };
            accounts.Add(operatingExpenses);

            // مصروفات رسوم البنوك
            accounts.Add(new ChartOfAccount
            {
                Id = Guid.NewGuid(),
                AccountNumber = "5101",
                NameAr = "رسوم البنوك",
                NameEn = "Bank Fees",
                AccountType = AccountType.Expenses,
                Category = AccountCategory.Sub,
                ParentAccountId = operatingExpenses.Id,
                NormalBalance = AccountNature.Debit,
                Level = 3,
                Description = "رسوم ومصروفات البنوك",
                IsActive = true,
                IsSystemAccount = true,
                CanPost = true,
                CreatedAt = DateTime.UtcNow
            });

            // مصروفات المستردات
            accounts.Add(new ChartOfAccount
            {
                Id = Guid.NewGuid(),
                AccountNumber = "5110",
                NameAr = "المستردات",
                NameEn = "Refunds",
                AccountType = AccountType.Expenses,
                Category = AccountCategory.Sub,
                ParentAccountId = operatingExpenses.Id,
                NormalBalance = AccountNature.Debit,
                Level = 3,
                Description = "المبالغ المستردة للعملاء",
                IsActive = true,
                IsSystemAccount = true,
                CanPost = true,
                CreatedAt = DateTime.UtcNow
            });

            // عمولات الوكلاء
            accounts.Add(new ChartOfAccount
            {
                Id = Guid.NewGuid(),
                AccountNumber = "5120",
                NameAr = "عمولات الوكلاء",
                NameEn = "Agent Commissions",
                AccountType = AccountType.Expenses,
                Category = AccountCategory.Sub,
                ParentAccountId = operatingExpenses.Id,
                NormalBalance = AccountNature.Debit,
                Level = 3,
                Description = "عمولات الوكلاء والوسطاء",
                IsActive = true,
                IsSystemAccount = true,
                CanPost = true,
                CreatedAt = DateTime.UtcNow
            });

            // مردودات المبيعات
            accounts.Add(new ChartOfAccount
            {
                Id = Guid.NewGuid(),
                AccountNumber = "5130",
                NameAr = "مردودات المبيعات",
                NameEn = "Sales Returns",
                AccountType = AccountType.Expenses,
                Category = AccountCategory.Sub,
                ParentAccountId = operatingExpenses.Id,
                NormalBalance = AccountNature.Debit,
                Level = 3,
                Description = "مردودات المبيعات والخصومات",
                IsActive = true,
                IsSystemAccount = true,
                CanPost = true,
                CreatedAt = DateTime.UtcNow
            });

            // خسائر الديون المعدومة
            accounts.Add(new ChartOfAccount
            {
                Id = Guid.NewGuid(),
                AccountNumber = "5140",
                NameAr = "خسائر الديون المعدومة",
                NameEn = "Bad Debt Expenses",
                AccountType = AccountType.Expenses,
                Category = AccountCategory.Sub,
                ParentAccountId = operatingExpenses.Id,
                NormalBalance = AccountNature.Debit,
                Level = 3,
                Description = "خسائر من عدم تحصيل المديونيات",
                IsActive = true,
                IsSystemAccount = true,
                CanPost = true,
                CreatedAt = DateTime.UtcNow
            });

            // إضافة جميع الحسابات إلى قاعدة البيانات
            await context.ChartOfAccounts.AddRangeAsync(accounts);
            await context.SaveChangesAsync();

            logger.LogInformation($"تم بذر {accounts.Count} حساب في دليل الحسابات بنجاح");
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "خطأ أثناء بذر الحسابات الأساسية في دليل الحسابات");
            throw;
        }
    }
}
