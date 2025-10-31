using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace YemenBooking.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddIsIndexedToProperty : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<bool>(
                name: "IsIndexed",
                table: "Properties",
                type: "boolean",
                nullable: false,
                defaultValue: false);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "IsIndexed",
                table: "Properties");
        }
    }
}
