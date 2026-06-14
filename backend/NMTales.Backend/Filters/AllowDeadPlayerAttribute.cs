using System;

namespace NMTales.Backend.Filters
{
    [AttributeUsage(AttributeTargets.Method | AttributeTargets.Class)]
    public class AllowDeadPlayerAttribute : Attribute
    {
    }
}
