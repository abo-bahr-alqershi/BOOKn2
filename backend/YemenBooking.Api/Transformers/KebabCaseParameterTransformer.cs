using Microsoft.AspNetCore.Routing;
using System.Text.RegularExpressions;

namespace YemenBooking.Api.Transformers
{
    public class KebabCaseParameterTransformer : IOutboundParameterTransformer
    {
        public string? TransformOutbound(object? value)
        {
            if (value == null) return null;
            var str = value.ToString();
            if (string.IsNullOrEmpty(str)) return null;
            // Insert hyphens between lowercase and uppercase letters, then lowercase entire string
            return Regex.Replace(str, "([a-z])([A-Z])", "$1-$2").ToLower();
        }
    }
}