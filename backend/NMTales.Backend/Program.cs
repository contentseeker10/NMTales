using System.Text;
using DotNetEnv;
using FluentValidation;
using FluentValidation.AspNetCore;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using NMTales.Backend.Data;
using NMTales.Backend.Repositories;
using NMTales.Backend.Repositories.Location;
using NMTales.Backend.Repositories.Notebook;
using NMTales.Backend.Repositories.Test;
using NMTales.Backend.Repositories.User;
using NMTales.Backend.Repositories.UserQuest;
using NMTales.Backend.Services;
using NMTales.Backend.Services.Auth;
using NMTales.Backend.Services.Location;
using NMTales.Backend.Services.Player;
using NMTales.Backend.Services.Test;
using NMTales.Backend.Services.UserQuest;
using NMTales.Backend.Validators;

namespace NMTales.Backend
{
    public class Program
    {
        // 1. Changed void to async Task so we can use await inside Main
        public static async Task Main(string[] args)
        {
            Env.Load();
            
            var builder = WebApplication.CreateBuilder(args);

            builder.Services.AddControllers();
            builder.Services.AddScoped<JwtService>();
            builder.Services.AddDbContext<ApplicationDbContext>(options =>
                options.UseNpgsql(
                    builder.Configuration.GetConnectionString("DefaultConnection"),
                    npgsqlOptionsAction: npgsqlOptions =>
                    {
                        npgsqlOptions.EnableRetryOnFailure(
                            maxRetryCount: 3, 
                            maxRetryDelay: TimeSpan.FromSeconds(5), 
                            errorCodesToAdd: null); 
                    }));
            
            builder.Services.AddScoped(typeof(IRepository<>), typeof(Repository<>));
            builder.Services.AddScoped<IQuestionRepository, QuestionRepository>();
            
            builder.Services.AddScoped<IUserRepository, UserRepository>();
            builder.Services.AddScoped<IAuthService, AuthService>();
            builder.Services.AddScoped<IPlayerService, PlayerService>();
            
            builder.Services.AddScoped<INotebookRepository, NotebookRepository>();
            builder.Services.AddScoped<INotebookService, NotebookService>();
            
            builder.Services.AddScoped<ILocationRepository, LocationRepository>();
            builder.Services.AddScoped<ILocationService, LocationService>();

            builder.Services.AddScoped<IUserQuestRepository, UserQuestRepository>();
            builder.Services.AddScoped<IUserQuestService, UserQuestService>();

            builder.Services.AddScoped<ITestRepository, TestRepository>();
            builder.Services.AddScoped<ITestService, TestService>();
            
            var jwtKey = builder.Configuration["Jwt:Key"]
                ?? throw new InvalidOperationException("Jwt:Key is not configured.");
            var signingKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtKey));

            builder.Services
                .AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
                .AddJwtBearer(options =>
                {
                    options.TokenValidationParameters = new TokenValidationParameters
                    {
                        ValidateIssuer = false,
                        ValidateAudience = false,
                        ValidateIssuerSigningKey = true,
                        IssuerSigningKey = signingKey,
                        ValidateLifetime = true,
                        ClockSkew = TimeSpan.Zero
                    };
                });

            builder.Configuration.AddEnvironmentVariables();

            builder.Services.AddEndpointsApiExplorer();
            builder.Services.AddSwaggerGen(options =>
            {
                options.SwaggerDoc("v1", new OpenApiInfo
                {
                    Title = "NMTales.Backend API",
                    Version = "v1"
                });

                options.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
                {
                    Name = "Authorization",
                    Type = SecuritySchemeType.Http,
                    Scheme = "bearer",
                    BearerFormat = "JWT",
                    In = ParameterLocation.Header,
                    Description = "Enter JWT token"
                });

                options.AddSecurityRequirement(new OpenApiSecurityRequirement
                {
                    {
                        new OpenApiSecurityScheme
                        {
                            Reference = new OpenApiReference
                            {
                                Type = ReferenceType.SecurityScheme,
                                Id = "Bearer"
                            }
                        },
                        Array.Empty<string>()
                    }
                });
            });

            builder.Services.AddCors(options => {
                options.AddDefaultPolicy(policy => {
                    policy.AllowAnyOrigin()    
                        .AllowAnyHeader()
                        .AllowAnyMethod();
                });
            });
            
            builder.Services.AddValidatorsFromAssemblyContaining<RegisterValidator>();

            var app = builder.Build();

            using (var scope = app.Services.CreateScope())
            {
                var db = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();
                
                // Only run migrations if connected to PostgreSQL, skip if using In-Memory for tests
                if (db.Database.IsRelational())
                {
                    await db.Database.MigrateAsync(); 
                }
                else
                {
                    // Test In-Memory DB: Instantly generate tables based on C# models
                    await db.Database.EnsureCreatedAsync(); 
                }
                
                DbSeeder.Seed(db);
            }

            app.UseCors();

            app.UseStaticFiles();

            if (app.Environment.IsDevelopment())
            {
                app.UseSwagger();
                app.UseSwaggerUI();
            }

            app.UseHttpsRedirection();
            app.UseAuthentication();
            app.UseAuthorization();

            app.MapControllers();

            app.Run();
        }
    }
}