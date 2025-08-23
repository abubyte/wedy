# Development Workflow

## Git Flow Process

This project uses Git Flow methodology for organized development and release management.

### Branch Strategy

- **main**: Production-ready code
- **develop**: Integration branch for ongoing development
- **feature/**: Feature development branches
- **release/**: Release preparation branches
- **hotfix/**: Critical fixes for production

### Feature Development

1. **Start new feature from develop**:
   ```bash
   git checkout develop
   git pull origin develop
   git flow feature start feature-name
   ```

2. **Work on feature with regular commits**:
   ```bash
   git add .
   git commit -m "feat(scope): description"
   ```

3. **Finish feature**:
   ```bash
   git flow feature finish feature-name
   ```

### Commit Message Convention

**Format**: `<type>(<scope>): <subject>`

**Types**:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation
- `style`: Formatting
- `refactor`: Code restructuring
- `test`: Adding tests
- `chore`: Maintenance

**Scopes**:
- `backend`: Backend changes
- `mobile`: Mobile app changes
- `auth`: Authentication
- `payment`: Payment system
- `db`: Database changes
- `infra`: Infrastructure

**Examples**:
```bash
git commit -m "feat(auth): implement OTP verification system"
git commit -m "fix(payment): resolve UzumBank webhook validation"
git commit -m "docs(api): update merchant API documentation"
```

### Pull Request Process

1. Create PR from feature branch to develop
2. Require at least 1 review
3. Run all tests and linting
4. Merge only when all checks pass

### Release Process

1. **Start release**:
   ```bash
   git flow release start v1.2.0
   ```

2. **Prepare release** (version bumps, changelog, etc.)

3. **Finish release**:
   ```bash
   git flow release finish v1.2.0
   ```

### Hotfix Process

1. **Start hotfix from main**:
   ```bash
   git flow hotfix start hotfix-name
   ```

2. **Fix the issue and test**

3. **Finish hotfix**:
   ```bash
   git flow hotfix finish hotfix-name
   ```

### Development Setup

1. **Clone repository**:
   ```bash
   git clone <repository-url>
   cd wedy
   ```

2. **Initialize Git Flow**:
   ```bash
   git flow init -d
   ```

3. **Switch to develop branch**:
   ```bash
   git checkout develop
   ```

### Quality Standards

- All code must pass linting and formatting
- All tests must pass
- Code coverage should be maintained
- Documentation must be updated for new features
- Commit messages must follow convention

### Code Review Guidelines

- Review for code quality and architecture
- Ensure business logic is correct
- Verify security considerations
- Check for proper error handling
- Validate test coverage

### Prohibited Actions

- Direct commits to main branch
- Force pushing to shared branches
- Committing with incorrect author attribution
- Merging without proper review

### Git Configuration

Ensure proper Git configuration:
```bash
git config user.name "abdurrohmandavron"
git config user.email "abdurakhmon278@gmail.com"
```

### Support

For questions about the development workflow, consult this document or ask the team lead.