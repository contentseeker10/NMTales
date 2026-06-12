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
    public DbSet<Location> Locations { get; set; }


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
