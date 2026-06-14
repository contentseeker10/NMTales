using Microsoft.EntityFrameworkCore;
using NMTales.Backend.Models;

namespace NMTales.Backend.Data;

public class ApplicationDbContext : DbContext
{
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


    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<User>()
            .HasIndex(user => user.Username)
            .IsUnique();
        
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
    }
}
