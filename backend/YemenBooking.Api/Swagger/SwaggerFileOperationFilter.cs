using System.Collections.Generic;
using System.Linq;
using Microsoft.AspNetCore.Http;
using Microsoft.OpenApi.Models;
using Swashbuckle.AspNetCore.SwaggerGen;

namespace YemenBooking.Api.Swagger
{
    /// <summary>
    /// يهيئ Swagger لتدعم رفع ملفات من نوع IFormFile في نماذج multipart/form-data
    /// Configures Swagger to support IFormFile uploads in multipart/form-data requests
    /// </summary>
    public class SwaggerFileOperationFilter : IOperationFilter
    {
        public void Apply(OpenApiOperation operation, OperationFilterContext context)
        {
            // Detect all IFormFile parameters, including nested DTO properties
            var fileParamNames = new List<string>();
            foreach (var param in context.MethodInfo.GetParameters())
            {
                var pt = param.ParameterType;
                if (pt == typeof(IFormFile) || typeof(IEnumerable<IFormFile>).IsAssignableFrom(pt))
                {
                    fileParamNames.Add(param.Name);
                }
                else
                {
                    // scan properties of DTOs
                    foreach (var prop in pt.GetProperties(System.Reflection.BindingFlags.Public | System.Reflection.BindingFlags.Instance))
                    {
                        if (prop.PropertyType == typeof(IFormFile) ||
                            typeof(IEnumerable<IFormFile>).IsAssignableFrom(prop.PropertyType))
                        {
                            fileParamNames.Add(prop.Name);
                        }
                    }
                }
            }
            if (!fileParamNames.Any())
                return;
            // define multipart/form-data request body schema for file upload
            operation.RequestBody = new OpenApiRequestBody
            {
                Content =
                {
                    ["multipart/form-data"] = new OpenApiMediaType
                    {
                        Schema = new OpenApiSchema
                        {
                            Type = "object",
                            Properties = fileParamNames.ToDictionary(
                                name => name,
                                name => new OpenApiSchema { Type = "string", Format = "binary" }
                            ),
                            Required = new HashSet<string>(fileParamNames)
                        }
                    }
                }
            };
        }
    }
} 