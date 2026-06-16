using Microsoft.EntityFrameworkCore;
using NMTales.Backend.Models;

namespace NMTales.Backend.Data;

/// <summary>
/// The primary Entity Framework Core database context for the application.
/// </summary>
/// <remarks>
/// Acts as the bridge between the application's domain models and the underlying relational database,
/// managing entity tracking, queries, and save operations.
/// </remarks>
public class ApplicationDbContext : DbContext
{
    /// <summary>
    /// Initializes a new instance of the <see cref="ApplicationDbContext"/> with the specified options.
    /// </summary>
    public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options)
        : base(options)
    {
    }

    public DbSet<User> Users {  get; set; }
    public DbSet<Question> Questions { get; set; }
    public DbSet<Answer> Answers { get; set; }
    public DbSet<UserQuest> UserQuests { get; set; }
    public DbSet<UserTestSession> UserTestSessions { get; set; }
    public DbSet<NotebookPage> NotebookPages { get; set; }
    public DbSet<AssistantMessage> AssistantMessages { get; set; }
    public DbSet<Achievement> Achievements { get; set; }
    public DbSet<UserAchievement> UserAchievements { get; set; }
    public DbSet<PlayerStats> PlayerStats { get; set; }
    public DbSet<Location> Locations { get; set; }

    /// <summary>
    /// Configures the database schema, including unique constraints and entity relationship mapping.
    /// </summary>
    /// <param name="modelBuilder">The builder used to construct the model for this context.</param>
    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        // Enforce unique usernames
        modelBuilder.Entity<User>()
            .HasIndex(user => user.Username)
            .IsUnique();
        
        // Cascade delete: If User dies, their NotebookPages die
        modelBuilder.Entity<NotebookPage>()
            .HasOne(p => p.User)
            .WithMany()
            .HasForeignKey(p => p.UserId)
            .OnDelete(DeleteBehavior.Cascade);

        modelBuilder.Entity<Achievement>()
            .HasIndex(a => a.Code)
            .IsUnique();

        modelBuilder.Entity<UserAchievement>()
            .HasOne(ua => ua.User)
            .WithMany()
            .HasForeignKey(ua => ua.UserId)
            .OnDelete(DeleteBehavior.Cascade);

        modelBuilder.Entity<UserAchievement>()
            .HasOne(ua => ua.Achievement)
            .WithMany()
            .HasForeignKey(ua => ua.AchievementId)
            .OnDelete(DeleteBehavior.Cascade);

        modelBuilder.Entity<PlayerStats>()
            .HasOne(ps => ps.User)
            .WithOne()
            .HasForeignKey<PlayerStats>(ps => ps.UserId)
            .OnDelete(DeleteBehavior.Cascade);

        // Cascade delete: If User dies, their TestSessions die
        modelBuilder.Entity<UserTestSession>()
            .HasOne(s => s.User)
            .WithMany()
            .HasForeignKey(s => s.UserId)
            .OnDelete(DeleteBehavior.Cascade);

        // Cascade delete: If Question dies, its Answers die
        modelBuilder.Entity<Answer>()
            .HasOne(a => a.Question)
            .WithMany(q => q.Answers)
            .HasForeignKey(a => a.QuestionId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}
