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
    }
}
