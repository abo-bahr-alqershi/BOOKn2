using Dapper;
using System.Data;

namespace YemenBooking.Infrastructure.Dapper
{
    /// <summary>
    /// يقوم بالتأكد من وجود الإجراءات المخزنة في قاعدة البيانات، وإنشاؤها إذا لم تكن موجودة
    /// Ensures stored procedures are created if missing
    /// </summary>
    public static class StoredProceduresInitializer
    {
        /// <summary>
        /// يتأكد من وجود sp_AdvancedPropertySearch في قاعدة البيانات
        /// Creates sp_AdvancedPropertySearch if not exists
        /// </summary>
        public static void EnsureAdvancedSearchProc(IDbConnection connection)
        {
            // Skip for PostgreSQL - SQL Server specific stored procedure
            // TODO: Rewrite this stored procedure for PostgreSQL syntax
            if(connection.GetType().Name.Contains("Npgsql", System.StringComparison.OrdinalIgnoreCase))
                return;
            
            // Ensure required SQL Server table types exist
            const string ensureTypesSql = @"
IF TYPE_ID(N'dbo.GuidList') IS NULL
    CREATE TYPE dbo.GuidList AS TABLE (Id UNIQUEIDENTIFIER NOT NULL);

IF TYPE_ID(N'dbo.JsonFilters') IS NULL
    CREATE TYPE dbo.JsonFilters AS TABLE (
        FieldId UNIQUEIDENTIFIER NULL,
        Value NVARCHAR(MAX) NULL
    );";
            connection.Execute(ensureTypesSql);

            const string procName = "sp_AdvancedPropertySearch";
            // التحقق من وجود الإجراء
            var exists = connection.ExecuteScalar<int>(
                "SELECT COUNT(*) FROM sys.objects WHERE object_id = OBJECT_ID(@Name) AND type = 'P'", new { Name = procName });
            if (exists == 0)
            {
                // تعريف الإجراء المخزن
                var sql = @"
CREATE PROCEDURE sp_AdvancedPropertySearch
    @PropertyTypeId UNIQUEIDENTIFIER = NULL,
    @FromDate DATETIME2 = NULL,
    @ToDate DATETIME2 = NULL,
    @MinPrice DECIMAL(18,2) = NULL,
    @MaxPrice DECIMAL(18,2) = NULL,
    @Currency NVARCHAR(10) = NULL,
    @PrimaryFieldFilters dbo.JsonFilters READONLY,
    @FieldFilters dbo.JsonFilters READONLY,
    @UnitTypeIds dbo.GuidList READONLY,
    @AmenityIds dbo.GuidList READONLY,
    @ServiceIds dbo.GuidList READONLY,
    @SortBy NVARCHAR(50),
    @IsAscending BIT = 0,
    @PageNumber INT = 1,
    @PageSize INT = 10
AS
BEGIN
    SET NOCOUNT ON;
    -- 1. حساب إجمالي عدد الكيانات المطابقة للفلترة
    SELECT COUNT(DISTINCT p.PropertyId)
    FROM Properties p
    LEFT JOIN Units u ON u.PropertyId = p.PropertyId
    LEFT JOIN PricingRules pr ON pr.UnitId = u.UnitId AND pr.StartDate <= @FromDate AND pr.EndDate >= @ToDate AND pr.Currency = @Currency
    WHERE p.IsDeleted = 0
      AND (@PropertyTypeId IS NULL OR p.TypeId = @PropertyTypeId)
      AND (@MinPrice IS NULL OR u.BasePrice_Amount >= @MinPrice)
      AND (@MaxPrice IS NULL OR u.BasePrice_Amount <= @MaxPrice);

    -- 2. جلب الصفحة المطلوبة من النتائج
    SELECT
        p.PropertyId AS Id,
        img.Url AS MainImageUrl,
        p.Name,
        ISNULL(AVG((r.Cleanliness + r.Service + r.Location + r.Value)/4.0), 0) AS AverageRating,
        0 AS IsFavorite,
        COUNT(r.Id) AS ReviewsCount,
        p.StarRating,
        u.BasePrice_Amount AS BasePrice,
        CASE WHEN pr.PriceAmount < u.BasePrice_Amount THEN pr.PriceAmount ELSE u.BasePrice_Amount END AS EffectivePrice,
        p.Latitude, p.Longitude
    FROM Properties p
    LEFT JOIN PropertyImages img ON img.PropertyId = p.PropertyId AND img.IsMainImage = 1 AND img.IsDeleted = 0
    LEFT JOIN Units u ON u.PropertyId = p.PropertyId
    LEFT JOIN PricingRules pr ON pr.UnitId = u.UnitId AND pr.StartDate <= @FromDate AND pr.EndDate >= @ToDate AND pr.Currency = @Currency
    LEFT JOIN Reviews r ON r.BookingId IN (SELECT BookingId FROM Bookings WHERE UnitId = u.UnitId)
    WHERE p.IsDeleted = 0
      AND (@PropertyTypeId IS NULL OR p.TypeId = @PropertyTypeId)
      AND (@MinPrice IS NULL OR u.BasePrice_Amount >= @MinPrice)
      AND (@MaxPrice IS NULL OR u.BasePrice_Amount <= @MaxPrice)
    GROUP BY p.PropertyId, img.Url, p.Name, p.StarRating, u.BasePrice_Amount, pr.PriceAmount, p.Latitude, p.Longitude
    ORDER BY 
        CASE WHEN @SortBy = 'name' THEN p.Name END ASC,
        CASE WHEN @SortBy = 'price' THEN CASE WHEN pr.PriceAmount < u.BasePrice_Amount THEN pr.PriceAmount ELSE u.BasePrice_Amount END END 
        OFFSET (@PageNumber - 1) * @PageSize ROWS
        FETCH NEXT @PageSize ROWS ONLY;
END";

                // تنفيذ إنشاء الإجراء
                connection.Execute(sql);
            }
        }
    }
} 