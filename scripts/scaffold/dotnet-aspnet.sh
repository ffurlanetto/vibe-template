# shellcheck shell=bash
STACK_TIER="B"
STACK_LABEL=".NET 8 / ASP.NET Core"
STACK_REQUIRES="dotnet"
STACK_DIRS="src/@@PROJECT_CAMEL@@.Api src/@@PROJECT_CAMEL@@.Domain src/@@PROJECT_CAMEL@@.Infrastructure tests/@@PROJECT_CAMEL@@.UnitTests tests/@@PROJECT_CAMEL@@.IntegrationTests"
CMD_INSTALL="dotnet restore"
CMD_TEST="dotnet test --collect:\"XPlat Code Coverage\""
CMD_LINT="dotnet format --verify-no-changes"
CMD_TYPECHECK="dotnet build --configuration Release /p:TreatWarningsAsErrors=true"
CMD_BUILD="dotnet build --configuration Release"
CMD_DEV="dotnet run --project src/@@PROJECT_CAMEL@@.Api"
CMD_AUDIT="dotnet list package --vulnerable --include-transitive"

STACK_DIRS="${STACK_DIRS//@@PROJECT_CAMEL@@/$PROJECT_CAMEL}"
CMD_DEV="${CMD_DEV//@@PROJECT_CAMEL@@/$PROJECT_CAMEL}"

stack_generate() {
  [[ -n "$(find "$DEST" -maxdepth 2 -name '*.csproj' 2>/dev/null)" ]] && { skip "a .csproj already exists"; return 0; }
  $DRY_RUN && { skip "would run dotnet new"; return 0; }
  ( cd "$DEST" \
    && dotnet new sln --name "$PROJECT_CAMEL" >/dev/null 2>&1 \
    && dotnet new webapi -o "src/${PROJECT_CAMEL}.Api" >/dev/null 2>&1 \
    && dotnet new xunit -o "tests/${PROJECT_CAMEL}.UnitTests" >/dev/null 2>&1 \
    && dotnet sln add "src/${PROJECT_CAMEL}.Api" "tests/${PROJECT_CAMEL}.UnitTests" >/dev/null 2>&1 ) || return 1
}
