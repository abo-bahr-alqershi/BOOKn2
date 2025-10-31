using System.Collections.Generic;

namespace YemenBooking.Core.Seeds
{
    /// <summary>
    /// واجهة لتعريف مولدات البيانات الأولية للكيانات
    /// </summary>
    public interface ISeeder<T>
    {
        /// <summary>
        /// يحصل على قائمة من العناصر الجاهزة للحقن في قاعدة البيانات
        /// </summary>
        IEnumerable<T> SeedData();
    }
} 