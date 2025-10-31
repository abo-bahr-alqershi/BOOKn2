// using System;
// using System.Collections.Generic;
// using System.IO;
// using System.Linq;
// using System.Threading;
// using System.Threading.Tasks;
// using LiteDB;
// using Microsoft.Extensions.Logging;
// using Microsoft.Extensions.Caching.Memory;
// using YemenBooking.Core.Entities;
// using YemenBooking.Core.Interfaces.Repositories;
// using YemenBooking.Application.Common.Interfaces;
// using YemenBooking.Application.Features.SearchAndFilters.Services;
// using YemenBooking.Application.Features.Units.Services;
// using YemenBooking.Application.Features.Pricing.Services;
// using YemenBooking.Core.Indexing.Models;
// using YemenBooking.Infrastructure.Indexing.Models;
// using YemenBooking.Infrastructure.Redis.Models;

// namespace YemenBooking.Infrastructure.Indexing.Services
// {
//     /// <summary>
//     /// خدمة الفهرسة الكاملة باستخدام LiteDB محسّنة للذاكرة المحدودة
//     /// </summary>
//     public class LiteDbIndexingService : IIndexingService, IDisposable
//     {
//         private readonly string _dbPath;
//         private readonly IPropertyRepository _propertyRepository;
//         private readonly IUnitRepository _unitRepository;
//         private readonly IAvailabilityService _availabilityService;
//         private readonly IPricingService _pricingService;
//         private readonly ILogger<LiteDbIndexingService> _logger;
//         private readonly IMemoryCache _cache;
//         private readonly SemaphoreSlim _semaphore = new(1, 1);
//         private readonly ConnectionString _connectionString;
//         private readonly ILiteDbWriteQueue _writeQueue;

//         public LiteDbIndexingService(
//             string dbPath,
//             IPropertyRepository propertyRepository,
//             IUnitRepository unitRepository,
//             IAvailabilityService availabilityService,
//             IPricingService pricingService,
//             IMemoryCache cache,
//             ILogger<LiteDbIndexingService> logger,
//             ILiteDbWriteQueue writeQueue)
//         {
//             _dbPath = dbPath;
//             _propertyRepository = propertyRepository;
//             _unitRepository = unitRepository;
//             _availabilityService = availabilityService;
//             _pricingService = pricingService;
//             _cache = cache;
//             _logger = logger;
//             _writeQueue = writeQueue;

//             // إعدادات محسّنة للذاكرة المحدودة (512MB)
//             _connectionString = new ConnectionString
//             {
//                 Filename = dbPath,
//                 Connection = ConnectionType.Shared,
//                 // CacheSize و LimitSize غير مدعومتين في بعض إصدارات LiteDB
//                 InitialSize = 1024 * 1024, // 1MB
//                 Upgrade = true
//             };

//             InitializeDatabase();
//         }

//         #region Database Initialization

//         private void InitializeDatabase()
//         {
//             try
//             {
//                 using var db = new LiteDatabase(_connectionString);
//                 InitializeDatabaseSchema(db);
//                 _logger.LogInformation("تم تهيئة قاعدة بيانات الفهرسة بنجاح");
//             }
//             catch (Exception ex)
//             {
//                 _logger.LogError(ex, "خطأ في تهيئة قاعدة بيانات الفهرسة");
//                 throw;
//             }
//         }

//         private void InitializeDatabaseSchema(LiteDatabase db)
//         {
//             // إنشاء المجموعات والفهارس
//             var properties = db.GetCollection<PropertyIndexDocument>("properties");
//             properties.EnsureIndex(x => x.City);
//             properties.EnsureIndex(x => x.PropertyType);
//             properties.EnsureIndex(x => x.MinPrice);
//             properties.EnsureIndex(x => x.AverageRating);
//             properties.EnsureIndex(x => x.NameLower);
//             properties.EnsureIndex(x => x.IsActive);
//             properties.EnsureIndex(x => x.CreatedAt);
            
//             var availability = db.GetCollection<AvailabilityIndexDocument>("availability");
//             availability.EnsureIndex(x => x.PropertyId);
//             availability.EnsureIndex(x => x.UnitId);
            
//             var pricing = db.GetCollection<PricingIndexDocument>("pricing");
//             pricing.EnsureIndex(x => x.PropertyId);
//             pricing.EnsureIndex(x => x.UnitId);
            
//             var cities = db.GetCollection<CityIndexDocument>("cities");
//             cities.EnsureIndex(x => x.City);
            
//             var amenities = db.GetCollection<AmenityIndexDocument>("amenities");
//             amenities.EnsureIndex(x => x.AmenityId);
            
//             var dynamicFields = db.GetCollection<DynamicFieldIndexDocument>("dynamic_fields");
//             dynamicFields.EnsureIndex(x => x.FieldName);
//             dynamicFields.EnsureIndex(x => x.FieldValue);
//         }

//         #endregion

//         #region Property CRUD Operations

//         /// <summary>
//         /// إنشاء فهرس لعقار جديد
//         /// </summary>
//         public async Task OnPropertyCreatedAsync(Guid propertyId, CancellationToken cancellationToken = default)
//         {
//             await _semaphore.WaitAsync(cancellationToken);
//             try
//             {
//                 var property = await _propertyRepository.GetPropertyByIdAsync(propertyId, cancellationToken);
//                 if (property == null) return;

//                 var indexDoc = await BuildPropertyIndexDocument(property, cancellationToken);
                
//                 await _writeQueue.EnqueueAsync(db =>
//                 {
//                     var collection = db.GetCollection<PropertyIndexDocument>("properties");
//                     collection.Insert(indexDoc);
//                     UpdateCityIndex(db, property.City, propertyId.ToString(), true);
//                     UpdateAmenityIndexes(db, indexDoc.AmenityIds, propertyId.ToString(), true);
//                     return Task.CompletedTask;
//                 }, $"Insert property index {propertyId}");
                
//                 // مسح الكاش
//                 InvalidateCache($"city_{property.City}");
                
//                 _logger.LogInformation("تم إنشاء فهرس للعقار {PropertyId}", propertyId);
//             }
//             catch (Exception ex)
//             {
//                 _logger.LogError(ex, "خطأ في إنشاء فهرس للعقار {PropertyId}", propertyId);
//             }
//             finally
//             {
//                 _semaphore.Release();
//             }
//         }

//         /// <summary>
//         /// تحديث فهرس عقار موجود
//         /// </summary>
//         public async Task OnPropertyUpdatedAsync(Guid propertyId, CancellationToken cancellationToken = default)
//         {
//             await _semaphore.WaitAsync(cancellationToken);
//             try
//             {
//                 var property = await _propertyRepository.GetPropertyByIdAsync(propertyId, cancellationToken);
//                 if (property == null)
//                 {
//                     await OnPropertyDeletedAsync(propertyId, cancellationToken);
//                     return;
//                 }

//                 var indexDoc = await BuildPropertyIndexDocument(property, cancellationToken);
                
//                 await _writeQueue.EnqueueAsync(db =>
//                 {
//                     var collection = db.GetCollection<PropertyIndexDocument>("properties");
//                     var oldDoc = collection.FindById(propertyId.ToString());
//                     if (oldDoc != null)
//                     {
//                         if (oldDoc.City != indexDoc.City)
//                         {
//                             UpdateCityIndex(db, oldDoc.City, propertyId.ToString(), false);
//                             UpdateCityIndex(db, indexDoc.City, propertyId.ToString(), true);
//                         }
//                         var removedAmenities = oldDoc.AmenityIds.Except(indexDoc.AmenityIds).ToList();
//                         var addedAmenities = indexDoc.AmenityIds.Except(oldDoc.AmenityIds).ToList();
//                         UpdateAmenityIndexes(db, removedAmenities, propertyId.ToString(), false);
//                         UpdateAmenityIndexes(db, addedAmenities, propertyId.ToString(), true);
//                     }
//                     collection.Update(indexDoc);
//                     return Task.CompletedTask;
//                 }, $"Update property index {propertyId}");
                
//                 InvalidateCache($"property_{propertyId}");
                
//                 _logger.LogInformation("تم تحديث فهرس العقار {PropertyId}", propertyId);
//             }
//             catch (Exception ex)
//             {
//                 _logger.LogError(ex, "خطأ في تحديث فهرس العقار {PropertyId}", propertyId);
//             }
//             finally
//             {
//                 _semaphore.Release();
//             }
//         }

//         /// <summary>
//         /// حذف فهرس عقار
//         /// </summary>
//         public async Task OnPropertyDeletedAsync(Guid propertyId, CancellationToken cancellationToken = default)
//         {
//             await _semaphore.WaitAsync(cancellationToken);
//             try
//             {
//                 await _writeQueue.EnqueueAsync(db =>
//                 {
//                     var collection = db.GetCollection<PropertyIndexDocument>("properties");
//                     var doc = collection.FindById(propertyId.ToString());
//                     if (doc != null)
//                     {
//                         collection.Delete(propertyId.ToString());
//                         UpdateCityIndex(db, doc.City, propertyId.ToString(), false);
//                         UpdateAmenityIndexes(db, doc.AmenityIds, propertyId.ToString(), false);
//                         db.GetCollection<AvailabilityIndexDocument>("availability")
//                             .DeleteMany(x => x.PropertyId == propertyId.ToString());
//                         db.GetCollection<PricingIndexDocument>("pricing")
//                             .DeleteMany(x => x.PropertyId == propertyId.ToString());
//                     }
//                     return Task.CompletedTask;
//                 }, $"Delete property index {propertyId}");
                
//                 InvalidateCache($"property_{propertyId}");
                
//                 _logger.LogInformation("تم حذف فهرس العقار {PropertyId}", propertyId);
//             }
//             catch (Exception ex)
//             {
//                 _logger.LogError(ex, "خطأ في حذف فهرس العقار {PropertyId}", propertyId);
//             }
//             finally
//             {
//                 _semaphore.Release();
//             }
//         }

//         #endregion

//         #region Unit CRUD Operations

//         /// <summary>
//         /// تحديث فهرس عند إنشاء وحدة
//         /// </summary>
//         public async Task OnUnitCreatedAsync(Guid unitId, Guid propertyId, CancellationToken cancellationToken = default)
//         {
//             await _semaphore.WaitAsync(cancellationToken);
//             try
//             {
//                 var unit = await _unitRepository.GetUnitByIdAsync(unitId, cancellationToken);
//                 if (unit == null) return;

//                 await _writeQueue.EnqueueAsync(db =>
//                 {
//                     var collection = db.GetCollection<PropertyIndexDocument>("properties");
//                     var propertyIndex = collection.FindById(propertyId.ToString());
//                     if (propertyIndex != null)
//                     {
//                         if (!propertyIndex.UnitIds.Contains(unitId.ToString()))
//                         {
//                             propertyIndex.UnitIds.Add(unitId.ToString());
//                         }
//                         propertyIndex.UnitsCount = propertyIndex.UnitIds.Count;
//                         if (unit.MaxCapacity > propertyIndex.MaxCapacity)
//                         {
//                             propertyIndex.MaxCapacity = unit.MaxCapacity;
//                         }
//                         var unitPrice = unit.BasePrice.Amount;
//                         if (unitPrice < propertyIndex.MinPrice || propertyIndex.MinPrice == 0)
//                         {
//                             propertyIndex.MinPrice = unitPrice;
//                         }
//                         propertyIndex.UpdatedAt = DateTime.UtcNow;
//                         collection.Update(propertyIndex);
//                     }
//                     var pricingCollection = db.GetCollection<PricingIndexDocument>("pricing");
//                     pricingCollection.Insert(new PricingIndexDocument
//                     {
//                         Id = unitId.ToString(),
//                         PropertyId = propertyId.ToString(),
//                         UnitId = unitId.ToString(),
//                         BasePrice = unit.BasePrice.Amount,
//                         Currency = unit.BasePrice.Currency,
//                         UpdatedAt = DateTime.UtcNow
//                     });
//                     return Task.CompletedTask;
//                 }, $"OnUnitCreated update + pricing insert {unitId}");
                
//                 InvalidateCache($"property_{propertyId}");
                
//                 _logger.LogInformation("تم تحديث الفهرس لإنشاء الوحدة {UnitId}", unitId);
//             }
//             catch (Exception ex)
//             {
//                 _logger.LogError(ex, "خطأ في تحديث الفهرس لإنشاء الوحدة {UnitId}", unitId);
//             }
//             finally
//             {
//                 _semaphore.Release();
//             }
//         }

//         /// <summary>
//         /// تحديث فهرس عند تعديل وحدة
//         /// </summary>
//         public async Task OnUnitUpdatedAsync(Guid unitId, Guid propertyId, CancellationToken cancellationToken = default)
//         {
//             await _semaphore.WaitAsync(cancellationToken);
//             try
//             {
//                 var unit = await _unitRepository.GetUnitByIdAsync(unitId, cancellationToken);
//                 if (unit == null) return;

//                 await _writeQueue.EnqueueAsync(async db =>
//                 {
//                     var pricingCollection = db.GetCollection<PricingIndexDocument>("pricing");
//                     var pricingDoc = pricingCollection.FindById(unitId.ToString());
//                     if (pricingDoc != null)
//                     {
//                         pricingDoc.BasePrice = unit.BasePrice.Amount;
//                         pricingDoc.Currency = unit.BasePrice.Currency;
//                         pricingDoc.UpdatedAt = DateTime.UtcNow;
//                         pricingCollection.Update(pricingDoc);
//                     }
//                     await RecalculatePropertyMinPrice(db, propertyId);
//                 }, $"OnUnitUpdated pricing update {unitId}");
                
//                 InvalidateCache($"property_{propertyId}");
                
//                 _logger.LogInformation("تم تحديث الفهرس لتعديل الوحدة {UnitId}", unitId);
//             }
//             catch (Exception ex)
//             {
//                 _logger.LogError(ex, "خطأ في تحديث الفهرس لتعديل الوحدة {UnitId}", unitId);
//             }
//             finally
//             {
//                 _semaphore.Release();
//             }
//         }

//         /// <summary>
//         /// تحديث فهرس عند حذف وحدة
//         /// </summary>
//         public async Task OnUnitDeletedAsync(Guid unitId, Guid propertyId, CancellationToken cancellationToken = default)
//         {
//             await _semaphore.WaitAsync(cancellationToken);
//             try
//             {
//                 await _writeQueue.EnqueueAsync(async db =>
//                 {
//                     var pricingCollection = db.GetCollection<PricingIndexDocument>("pricing");
//                     pricingCollection.Delete(unitId.ToString());
//                     var availabilityCollection = db.GetCollection<AvailabilityIndexDocument>("availability");
//                     availabilityCollection.DeleteMany(x => x.UnitId == unitId.ToString());
//                     var propertyCollection = db.GetCollection<PropertyIndexDocument>("properties");
//                     var propertyDoc = propertyCollection.FindById(propertyId.ToString());
//                     if (propertyDoc != null)
//                     {
//                         propertyDoc.UnitIds.Remove(unitId.ToString());
//                         propertyDoc.UnitsCount = propertyDoc.UnitIds.Count;
//                         propertyDoc.UpdatedAt = DateTime.UtcNow;
//                         propertyCollection.Update(propertyDoc);
//                         await RecalculatePropertyMinPrice(db, propertyId);
//                         await RecalculatePropertyMaxCapacity(db, propertyId);
//                     }
//                 }, $"OnUnitDeleted cleanup {unitId}");
                
//                 InvalidateCache($"property_{propertyId}");
                
//                 _logger.LogInformation("تم تحديث الفهرس لحذف الوحدة {UnitId}", unitId);
//             }
//             catch (Exception ex)
//             {
//                 _logger.LogError(ex, "خطأ في تحديث الفهرس لحذف الوحدة {UnitId}", unitId);
//             }
//             finally
//             {
//                 _semaphore.Release();
//             }
//         }

//         #endregion

//         #region Availability Operations

//         /// <summary>
//         /// تحديث فهرس الإتاحة
//         /// </summary>
//         public async Task OnAvailabilityChangedAsync(Guid unitId, Guid propertyId, List<(DateTime Start, DateTime End)> availableRanges, CancellationToken cancellationToken = default)
//         {
//             await _semaphore.WaitAsync(cancellationToken);
//             try
//             {
//                 await _writeQueue.EnqueueAsync(db =>
//                 {
//                     var collection = db.GetCollection<AvailabilityIndexDocument>("availability");
//                     var doc = collection.FindOne(x => x.UnitId == unitId.ToString());
//                     if (doc == null)
//                     {
//                         doc = new AvailabilityIndexDocument
//                         {
//                             Id = $"{propertyId}_{unitId}",
//                             PropertyId = propertyId.ToString(),
//                             UnitId = unitId.ToString()
//                         };
//                     }
//                     doc.AvailableRanges = availableRanges.Select(r => new DateRangeIndex
//                     {
//                         StartDate = r.Start,
//                         EndDate = r.End
//                     }).ToList();
//                     doc.UpdatedAt = DateTime.UtcNow;
//                     collection.Upsert(doc);
//                     return Task.CompletedTask;
//                 }, $"OnAvailabilityChanged upsert {unitId}");
                
//                 InvalidateCache($"availability_{propertyId}");
                
//                 _logger.LogInformation("تم تحديث فهرس الإتاحة للوحدة {UnitId}", unitId);
//             }
//             catch (Exception ex)
//             {
//                 _logger.LogError(ex, "خطأ في تحديث فهرس الإتاحة للوحدة {UnitId}", unitId);
//             }
//             finally
//             {
//                 _semaphore.Release();
//             }
//         }

//         #endregion

//         #region Pricing Operations

//         /// <summary>
//         /// تحديث فهرس التسعير
//         /// </summary>
//         public async Task OnPricingRuleChangedAsync(Guid unitId, Guid propertyId, List<PricingRule> pricingRules, CancellationToken cancellationToken = default)
//         {
//             await _semaphore.WaitAsync(cancellationToken);
//             try
//             {
//                 await _writeQueue.EnqueueAsync(async db =>
//                 {
//                     var collection = db.GetCollection<PricingIndexDocument>("pricing");
//                     var doc = collection.FindById(unitId.ToString());
//                     if (doc != null)
//                     {
//                         doc.PricingRules = pricingRules.Select(r => new PricingRuleIndex
//                         {
//                             StartDate = r.StartDate,
//                             EndDate = r.EndDate,
//                             Price = r.PriceAmount,
//                             RuleType = r.PriceType
//                         }).ToList();
//                         doc.UpdatedAt = DateTime.UtcNow;
//                         collection.Update(doc);
//                         await RecalculatePropertyMinPrice(db, propertyId);
//                     }
//                 }, $"OnPricingRuleChanged update {unitId}");
                
//                 InvalidateCache($"pricing_{propertyId}");
                
//                 _logger.LogInformation("تم تحديث فهرس التسعير للوحدة {UnitId}", unitId);
//             }
//             catch (Exception ex)
//             {
//                 _logger.LogError(ex, "خطأ في تحديث فهرس التسعير للوحدة {UnitId}", unitId);
//             }
//             finally
//             {
//                 _semaphore.Release();
//             }
//         }

//         #endregion

//         #region Dynamic Fields Operations

//         /// <summary>
//         /// تحديث فهرس الحقول الديناميكية
//         /// </summary>
//         public async Task OnDynamicFieldChangedAsync(Guid propertyId, string fieldName, string fieldValue, bool isAdd, CancellationToken cancellationToken = default)
//         {
//             await _semaphore.WaitAsync(cancellationToken);
//             try
//             {
//                 await _writeQueue.EnqueueAsync(db =>
//                 {
//                     var propertyCollection = db.GetCollection<PropertyIndexDocument>("properties");
//                     var propertyDoc = propertyCollection.FindById(propertyId.ToString());
//                     if (propertyDoc != null)
//                     {
//                         if (isAdd)
//                         {
//                             propertyDoc.DynamicFields[fieldName] = fieldValue;
//                         }
//                         else
//                         {
//                             propertyDoc.DynamicFields.Remove(fieldName);
//                         }
//                         propertyDoc.UpdatedAt = DateTime.UtcNow;
//                         propertyCollection.Update(propertyDoc);
//                     }
//                     var dynamicCollection = db.GetCollection<DynamicFieldIndexDocument>("dynamic_fields");
//                     var dynamicKey = $"{fieldName}:{fieldValue}";
//                     var dynamicDoc = dynamicCollection.FindOne(x => x.FieldName == fieldName && x.FieldValue == fieldValue);
//                     if (dynamicDoc == null && isAdd)
//                     {
//                         dynamicDoc = new DynamicFieldIndexDocument
//                         {
//                             Id = dynamicKey,
//                             FieldName = fieldName,
//                             FieldValue = fieldValue,
//                             PropertyIds = new List<string> { propertyId.ToString() },
//                             UpdatedAt = DateTime.UtcNow
//                         };
//                         dynamicCollection.Insert(dynamicDoc);
//                     }
//                     else if (dynamicDoc != null)
//                     {
//                         if (isAdd)
//                         {
//                             if (!dynamicDoc.PropertyIds.Contains(propertyId.ToString()))
//                             {
//                                 dynamicDoc.PropertyIds.Add(propertyId.ToString());
//                             }
//                         }
//                         else
//                         {
//                             dynamicDoc.PropertyIds.Remove(propertyId.ToString());
//                         }
//                         if (dynamicDoc.PropertyIds.Any())
//                         {
//                             dynamicDoc.UpdatedAt = DateTime.UtcNow;
//                             dynamicCollection.Update(dynamicDoc);
//                         }
//                         else
//                         {
//                             dynamicCollection.Delete(dynamicDoc.Id);
//                         }
//                     }
//                     return Task.CompletedTask;
//                 }, $"OnDynamicFieldChanged {fieldName}");
                
//                 InvalidateCache($"field_{fieldName}");
                
//                 _logger.LogInformation("تم تحديث الحقل الديناميكي {FieldName} للعقار {PropertyId}", fieldName, propertyId);
//             }
//             catch (Exception ex)
//             {
//                 _logger.LogError(ex, "خطأ في تحديث الحقل الديناميكي {FieldName} للعقار {PropertyId}", fieldName, propertyId);
//             }
//             finally
//             {
//                 _semaphore.Release();
//             }
//         }

//         #endregion

//         #region Search Operations

//         /// <summary>
//         /// البحث في الفهرس
//         /// </summary>
//         public async Task<PropertySearchResult> SearchAsync(PropertySearchRequest request, CancellationToken cancellationToken = default)
//         {
//             // محاولة جلب من الكاش
//             var cacheKey = GenerateCacheKey(request);
//             if (_cache.TryGetValue<PropertySearchResult>(cacheKey, out var cachedResult))
//             {
//                 _logger.LogDebug("إرجاع نتائج البحث من الكاش");
//                 return cachedResult;
//             }

//             await _semaphore.WaitAsync(cancellationToken);
//             try
//             {
//                 using (var db = new LiteDatabase(_connectionString))
//                 {
//                     var collection = db.GetCollection<PropertyIndexDocument>("properties");
                    

//                     // بناء الاستعلام
//                     var query = collection.Query()
//                         .Where(x => x.IsApproved);
                    
//                     _logger.LogInformation(" ##1********************** {Count}", query.Count());

//                     // فلترة النص
//                     if (!string.IsNullOrWhiteSpace(request.SearchText))
//                     {
//                         var searchLower = request.SearchText.ToLower();
//                         query = query.Where(x =>
//                             x.NameLower.Contains(searchLower) ||
//                             x.DescriptionLower.Contains(searchLower) ||
//                             x.Address.Contains(searchLower));
//                     }
//                     _logger.LogInformation(" ##2********************** {Count}", query.Count());

//                     // فلترة المدينة
//                     if (!string.IsNullOrWhiteSpace(request.City))
//                     {
//                         query = query.Where(x => x.City == request.City);
//                     }

//                     _logger.LogInformation(" ##3********************** {Count}", query.Count());
//                     // فلترة نوع العقار
//                     if (!string.IsNullOrWhiteSpace(request.PropertyType))
//                     {
//                         query = query.Where(x => x.PropertyType == request.PropertyType);
//                     }
//                     _logger.LogInformation(" ##4********************** {Count}", query.Count());

//                     // فلترة السعر
//                     if (request.MinPrice.HasValue)
//                     {
//                         query = query.Where(x => x.MinPrice >= request.MinPrice.Value);
//                     }
//                     _logger.LogInformation(" ##5********************** {Count}", query.Count());
//                     if (request.MaxPrice.HasValue)
//                     {
//                         query = query.Where(x => x.MinPrice <= request.MaxPrice.Value);
//                     }
//                     _logger.LogInformation(" ##6********************** {Count}", query.Count());

//                     // فلترة التقييم
//                     if (request.MinRating.HasValue)
//                     {
//                         query = query.Where(x => x.AverageRating >= request.MinRating.Value);
//                     }
//                     _logger.LogInformation(" ##7********************** {Count}", query.Count());
//                     // فلترة السعة
//                     if (request.GuestsCount.HasValue)
//                     {
//                         query = query.Where(x => x.MaxCapacity >= request.GuestsCount.Value);
//                     }
//                     _logger.LogInformation(" ##8********************** {Count}", query.Count());

//                     // جلب كل النتائج للفلترة المتقدمة
//                     var allResults = query.ToList();
                    
//                     // فلترة المرافق
//                     if (request.RequiredAmenityIds?.Any() == true)
//                     {
//                         allResults = allResults.Where(p => 
//                             request.RequiredAmenityIds.All(amenityId => 
//                                 p.AmenityIds.Contains(amenityId))).ToList();
//                     }
//                     _logger.LogInformation(" ##9********************** {Count}", allResults.Count());

//                     // فلترة الخدمات
//                     if (request.ServiceIds?.Any() == true)
//                     {
//                         allResults = allResults.Where(p =>
//                             p.ServiceIds != null && request.ServiceIds.All(serviceId => p.ServiceIds.Contains(serviceId))
//                         ).ToList();
//                     }
//                     _logger.LogInformation(" ##9.1********************** {Count}", allResults.Count());

//                     // فلترة الإتاحة
//                     if (request.CheckIn.HasValue && request.CheckOut.HasValue)
//                     {
//                         var availablePropertyIds = await GetAvailableProperties(
//                             db, request.CheckIn.Value, request.CheckOut.Value, cancellationToken);
                        
//                         allResults = allResults.Where(p => 
//                             availablePropertyIds.Contains(p.Id)).ToList();
//                     }
//                     _logger.LogInformation(" ##10********************** {Count}", allResults.Count());

//                     // فلترة الحقول الديناميكية
//                     if (request.DynamicFieldFilters?.Any() == true)
//                     {
//                         foreach (var filter in request.DynamicFieldFilters)
//                         {
//                             allResults = allResults.Where(p =>
//                                 p.DynamicFields.ContainsKey(filter.Key) &&
//                                 p.DynamicFields[filter.Key] == filter.Value).ToList();
//                         }
//                     }
//                     _logger.LogInformation(" ##11********************** {Count}", allResults.Count());
                   
//                     // البحث الجغرافي
//                     if (request.Latitude.HasValue && request.Longitude.HasValue)
//                     {
//                         var radiusKm = request.RadiusKm ?? 50;
//                         allResults = allResults.Where(p =>
//                         {
//                             var distance = CalculateDistance(
//                                 request.Latitude.Value, request.Longitude.Value,
//                                 p.Latitude, p.Longitude);
//                             return distance <= radiusKm;
//                         }).ToList();
//                     }
//                     _logger.LogInformation(" ##12********************** {Count}", allResults.Count());
//                     // الترتيب
//                     allResults = ApplySorting(allResults, request.SortBy, request.Latitude, request.Longitude);
                    
//                     // العدد الكلي
//                     var totalCount = allResults.Count;
                    
//                     // التصفح
//                     var pagedResults = allResults
//                         .Skip((request.PageNumber - 1) * request.PageSize)
//                         .Take(request.PageSize)
//                         .ToList();
                    
//                     var result = new PropertySearchResult
//                     {
//                         Properties = pagedResults.Select(p => new PropertySearchItem
//                         {
//                             Id = p.Id,
//                             Name = p.Name,
//                             City = p.City,
//                             PropertyType = p.PropertyType,
//                             MinPrice = p.MinPrice,
//                             Currency = p.Currency,
//                             AverageRating = p.AverageRating,
//                             StarRating = p.StarRating,
//                             ImageUrls = p.ImageUrls,
//                             MaxCapacity = p.MaxCapacity,
//                             UnitsCount = p.UnitsCount,
//                             DynamicFields = p.DynamicFields,
//                             Latitude = p.Latitude,
//                             Longitude = p.Longitude
//                         }).ToList(),
//                         TotalCount = totalCount,
//                         PageNumber = request.PageNumber,
//                         PageSize = request.PageSize,
//                         TotalPages = (int)Math.Ceiling((double)totalCount / request.PageSize)
//                     };
                    
//                     // حفظ في الكاش لمدة 5 دقائق
//                     _cache.Set(cacheKey, result, TimeSpan.FromMinutes(5));
                    
//                     return result;
//                 }
//             }
//             catch (Exception ex)
//             {
//                 _logger.LogError(ex, "خطأ في البحث في الفهرس");
//                 throw;
//             }
//             finally
//             {
//                 _semaphore.Release();
//             }
//         }

//         #endregion

//         #region Helper Methods

//         private async Task<PropertyIndexDocument> BuildPropertyIndexDocument(Property property, CancellationToken cancellationToken)
//         {
//             var units = await _unitRepository.GetByPropertyIdAsync(property.Id, cancellationToken);

//             // Ensure property type name is resolved even if navigation not loaded
//             var typeName = property.PropertyType?.Name;
//             if (string.IsNullOrWhiteSpace(typeName))
//             {
//                 var type = await _propertyRepository.GetPropertyTypeByIdAsync(property.TypeId, cancellationToken);
//                 typeName = type?.Name ?? string.Empty;
//             }

//             // Ensure amenities are available even if navigation not loaded
//             var amenityList = property.Amenities?.ToList();
//             if (amenityList == null || amenityList.Count == 0)
//             {
//                 var amenities = await _propertyRepository.GetPropertyAmenitiesAsync(property.Id, cancellationToken);
//                 amenityList = amenities?.ToList() ?? new List<PropertyAmenity>();
//             }
//             var amenityIds = amenityList.Where(a => a.IsAvailable)
//                                          .Select(a => a.PtaId.ToString())
//                                          .ToList();
            
//             var doc = new PropertyIndexDocument
//             {
//                 Id = property.Id.ToString(),
//                 Name = property.Name,
//                 NameLower = property.Name.ToLower(),
//                 Description = property.Description ?? "",
//                 DescriptionLower = (property.Description ?? "").ToLower(),
//                 City = property.City,
//                 Address = property.Address,
//                 PropertyType = typeName,
//                 PropertyTypeId = property.TypeId,
//                 OwnerId = property.OwnerId,
//                 MinPrice = units.Any() ? units.Min(u => u.BasePrice.Amount) : 0,
//                 MaxPrice = units.Any() ? units.Max(u => u.BasePrice.Amount) : 0,
//                 Currency = property.Currency,
//                 StarRating = property.StarRating,
//                 AverageRating = property.AverageRating,
//                 ReviewsCount = property.Reviews?.Count ?? 0,
//                 ViewCount = property.ViewCount,
//                 BookingCount = property.BookingCount,
//                 Latitude = (double)property.Latitude,
//                 Longitude = (double)property.Longitude,
//                 MaxCapacity = units.Any() ? units.Max(u => u.MaxCapacity) : 0,
//                 UnitsCount = units.Count(),
//                 IsActive = true,
//                 IsFeatured = property.IsFeatured,
//                 IsApproved = property.IsApproved,
//                 UnitIds = units.Select(u => u.Id.ToString()).ToList(),
//                 AmenityIds = amenityIds,
//                 ServiceIds = property.Services?.Select(s => s.Id.ToString()).ToList() ?? new List<string>(),
//                 ImageUrls = property.Images?.OrderByDescending(i => i.IsMain)
//                     .Select(i => i.Url).ToList() ?? new List<string>(),
//                 DynamicFields = new Dictionary<string, string>(),
//                 CreatedAt = property.CreatedAt,
//                 UpdatedAt = DateTime.UtcNow
//             };
            
//             return doc;
//         }

//         private void UpdateCityIndex(LiteDatabase db, string city, string propertyId, bool isAdd)
//         {
//             var collection = db.GetCollection<CityIndexDocument>("cities");
//             var doc = collection.FindById(city);
            
//             if (doc == null && isAdd)
//             {
//                 doc = new CityIndexDocument
//                 {
//                     City = city,
//                     PropertyCount = 1,
//                     PropertyIds = new List<string> { propertyId },
//                     UpdatedAt = DateTime.UtcNow
//                 };
//                 collection.Insert(doc);
//             }
//             else if (doc != null)
//             {
//                 if (isAdd)
//                 {
//                     if (!doc.PropertyIds.Contains(propertyId))
//                     {
//                         doc.PropertyIds.Add(propertyId);
//                         doc.PropertyCount++;
//                     }
//                 }
//                 else
//                 {
//                     doc.PropertyIds.Remove(propertyId);
//                     doc.PropertyCount = Math.Max(0, doc.PropertyCount - 1);
//                 }
                
//                 doc.UpdatedAt = DateTime.UtcNow;
                
//                 if (doc.PropertyCount > 0)
//                 {
//                     collection.Update(doc);
//                 }
//                 else
//                 {
//                     collection.Delete(city);
//                 }
//             }
//         }

//         private void UpdateAmenityIndexes(LiteDatabase db, List<string> amenityIds, string propertyId, bool isAdd)
//         {
//             var collection = db.GetCollection<AmenityIndexDocument>("amenities");
            
//             foreach (var amenityId in amenityIds)
//             {
//                 var doc = collection.FindById(amenityId);
                
//                 if (doc == null && isAdd)
//                 {
//                     doc = new AmenityIndexDocument
//                     {
//                         AmenityId = amenityId,
//                         PropertyCount = 1,
//                         PropertyIds = new List<string> { propertyId },
//                         UpdatedAt = DateTime.UtcNow
//                     };
//                     collection.Insert(doc);
//                 }
//                 else if (doc != null)
//                 {
//                     if (isAdd)
//                     {
//                         if (!doc.PropertyIds.Contains(propertyId))
//                         {
//                             doc.PropertyIds.Add(propertyId);
//                             doc.PropertyCount++;
//                         }
//                     }
//                     else
//                     {
//                         doc.PropertyIds.Remove(propertyId);
//                         doc.PropertyCount = Math.Max(0, doc.PropertyCount - 1);
//                     }
                    
//                     doc.UpdatedAt = DateTime.UtcNow;
                    
//                     if (doc.PropertyCount > 0)
//                     {
//                         collection.Update(doc);
//                     }
//                     else
//                     {
//                         collection.Delete(amenityId);
//                     }
//                 }
//             }
//         }

//         private async Task RecalculatePropertyMinPrice(LiteDatabase db, Guid propertyId)
//         {
//             var pricingCollection = db.GetCollection<PricingIndexDocument>("pricing");
//             var prices = pricingCollection.Find(x => x.PropertyId == propertyId.ToString())
//                 .Select(x => x.BasePrice)
//                 .ToList();
            
//             if (prices.Any())
//             {
//                 var propertyCollection = db.GetCollection<PropertyIndexDocument>("properties");
//                 var propertyDoc = propertyCollection.FindById(propertyId.ToString());
                
//                 if (propertyDoc != null)
//                 {
//                     propertyDoc.MinPrice = prices.Min();
//                     propertyDoc.MaxPrice = prices.Max();
//                     propertyDoc.UpdatedAt = DateTime.UtcNow;
//                     propertyCollection.Update(propertyDoc);
//                 }
//             }
//         }

//         private async Task RecalculatePropertyMaxCapacity(LiteDatabase db, Guid propertyId)
//         {
//             var units = await _unitRepository.GetByPropertyIdAsync(propertyId);
            
//             if (units.Any())
//             {
//                 var propertyCollection = db.GetCollection<PropertyIndexDocument>("properties");
//                 var propertyDoc = propertyCollection.FindById(propertyId.ToString());
                
//                 if (propertyDoc != null)
//                 {
//                     propertyDoc.MaxCapacity = units.Max(u => u.MaxCapacity);
//                     propertyDoc.UpdatedAt = DateTime.UtcNow;
//                     propertyCollection.Update(propertyDoc);
//                 }
//             }
//         }

//         private async Task<HashSet<string>> GetAvailableProperties(
//             LiteDatabase db, 
//             DateTime checkIn, 
//             DateTime checkOut,
//             CancellationToken cancellationToken)
//         {
//             var availabilityCollection = db.GetCollection<AvailabilityIndexDocument>("availability");
//             // Use in-memory filtering to avoid LiteDB limitation: Any/All requires simple parameter on left side
//             var availableDocs = availabilityCollection
//                 .FindAll()
//                 .Where(x => x.AvailableRanges != null && x.AvailableRanges.Any(r => r.StartDate <= checkIn && r.EndDate >= checkOut))
//                 .ToList();
            
//             return availableDocs.Select(x => x.PropertyId).ToHashSet();
//         }

//         private List<PropertyIndexDocument> ApplySorting(List<PropertyIndexDocument> properties, string? sortBy, double? lat, double? lon)
//         {
//             return sortBy?.ToLower() switch
//             {
//                 "price_asc" => properties.OrderBy(p => p.MinPrice).ToList(),
//                 "price_desc" => properties.OrderByDescending(p => p.MinPrice).ToList(),
//                 "rating" => properties.OrderByDescending(p => p.AverageRating)
//                     .ThenByDescending(p => p.ReviewsCount).ToList(),
//                 "newest" => properties.OrderByDescending(p => p.CreatedAt).ToList(),
//                 "popularity" => properties.OrderByDescending(p => p.BookingCount)
//                     .ThenByDescending(p => p.ViewCount).ToList(),
//                 "distance" => (lat.HasValue && lon.HasValue)
//                     ? properties.OrderBy(p => CalculateDistance(lat.Value, lon.Value, p.Latitude, p.Longitude)).ToList()
//                     : properties,
//                 _ => properties.OrderByDescending(p => p.AverageRating)
//                     .ThenByDescending(p => p.ReviewsCount).ToList()
//             };
//         }

//         private double CalculateDistance(double lat1, double lon1, double lat2, double lon2)
//         {
//             const double R = 6371; // كيلومتر
//             var dLat = ToRadians(lat2 - lat1);
//             var dLon = ToRadians(lon2 - lon1);
//             var a = Math.Sin(dLat / 2) * Math.Sin(dLat / 2) +
//                     Math.Cos(ToRadians(lat1)) * Math.Cos(ToRadians(lat2)) *
//                     Math.Sin(dLon / 2) * Math.Sin(dLon / 2);
//             var c = 2 * Math.Atan2(Math.Sqrt(a), Math.Sqrt(1 - a));
//             return R * c;
//         }

//         private double ToRadians(double degrees) => degrees * Math.PI / 180;

//         private void InvalidateCache(string prefix)
//         {
//             // مسح الكاش المتعلق بالبادئة
//             _logger.LogDebug("مسح الكاش للبادئة: {Prefix}", prefix);
//         }

//         private string GenerateCacheKey(PropertySearchRequest request)
//         {
//             var key = $"search_{request.SearchText}_{request.City}_{request.PropertyType}";
//             key += $"_{request.MinPrice}_{request.MaxPrice}_{request.MinRating}";
//             key += $"_{request.CheckIn?.Ticks}_{request.CheckOut?.Ticks}";
//             key += $"_{request.PageNumber}_{request.PageSize}";
//             return key;
//         }

//         #endregion

//         #region Maintenance Operations

//         /// <summary>
//         /// تنظيف وصيانة قاعدة البيانات
//         /// </summary>
//         public async Task OptimizeDatabaseAsync()
//         {
//             await _semaphore.WaitAsync();
//             try
//             {
//                 await _writeQueue.EnqueueAsync(db =>
//                 {
//                     var originalSize = new FileInfo(_dbPath).Length;
//                     db.Rebuild();
//                     var newSize = new FileInfo(_dbPath).Length;
//                     _logger.LogInformation("تم ضغط قاعدة البيانات من {OriginalSize} إلى {NewSize} بايت", originalSize, newSize);
//                     var cutoffDate = DateTime.UtcNow.AddDays(-90);
//                     var availabilityCollection = db.GetCollection<AvailabilityIndexDocument>("availability");
//                     var oldAvailability = availabilityCollection.DeleteMany(x => x.UpdatedAt < cutoffDate);
//                     _logger.LogInformation("تم حذف {Count} سجل إتاحة قديم", oldAvailability);
//                     return Task.CompletedTask;
//                 }, "OptimizeDatabase");
//             }
//             catch (Exception ex)
//             {
//                 _logger.LogError(ex, "خطأ في صيانة قاعدة البيانات");
//             }
//             finally
//             {
//                 _semaphore.Release();
//             }
//         }

//         /// <summary>
//         /// إعادة بناء الفهرس بالكامل
//         /// </summary>
//         public async Task RebuildIndexAsync(CancellationToken cancellationToken = default)
//         {
//             _logger.LogInformation("بدء إعادة بناء الفهرس");

//             // احجز القفل فقط للجزء الحرج (إعادة تهيئة قاعدة البيانات)
//             await _semaphore.WaitAsync(cancellationToken);
//             try
//             {
//                 // مسح الفهرس الحالي وإعادة التهيئة
//                 File.Delete(_dbPath);
//                 InitializeDatabase();
//             }
//             catch (Exception ex)
//             {
//                 _logger.LogError(ex, "خطأ أثناء تهيئة قاعدة بيانات الفهرسة قبل إعادة البناء");
//                 throw;
//             }
//             finally
//             {
//                 _semaphore.Release();
//             }

//             try
//             {
//                 // إعادة بناء من البيانات الأساسية
//                 var properties = await _propertyRepository.GetActivePropertiesAsync(cancellationToken);
//                 var totalCount = properties.Count();
//                 var processed = 0;

//                 foreach (var property in properties)
//                 {
//                     cancellationToken.ThrowIfCancellationRequested();

//                     // ملاحظة: لا نحتفظ بالقفل هنا لأن OnPropertyCreatedAsync يقوم بأخذ القفل داخليًا
//                     await OnPropertyCreatedAsync(property.Id, cancellationToken);

//                     processed++;
//                     if (processed % 100 == 0)
//                     {
//                         _logger.LogInformation("تمت معالجة {Processed}/{Total} عقار", processed, totalCount);
//                     }
//                 }

//                 _logger.LogInformation("اكتملت إعادة بناء الفهرس. تمت معالجة {Count} عقار", processed);
//             }
//             catch (Exception ex)
//             {
//                 _logger.LogError(ex, "خطأ في إعادة بناء الفهرس");
//                 throw;
//             }
//         }

//         #endregion

//         public void Dispose()
//         {
//             _semaphore?.Dispose();
//         }
//     }
// }