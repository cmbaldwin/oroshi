# Ralph Realizations

Quick reference for patterns, gotchas, and constraints discovered during development.

<!--
Entry Format Template:
## [Category] - [Short Title]

**Problem:** What was going wrong or could go wrong
**Solution:** How to fix or avoid it
**Code Example:**
```ruby
# Example code here
```
**Gotcha:** Any non-obvious edge cases
**Related:** Links to relevant files or documentation
-->

## Table of Contents

- [Rails & ActiveRecord](#rails--activerecord)
- [Turbo & Stimulus](#turbo--stimulus)
- [Testing](#testing)
- [Database & Migrations](#database--migrations)
- [Asset Pipeline](#asset-pipeline)
- [Internationalization](#internationalization)
- [Authentication & Authorization](#authentication--authorization)
- [Background Jobs](#background-jobs)

---

## Rails & ActiveRecord

*Entries for ActiveRecord patterns, model callbacks, associations, and query gotchas.*

### User.insert vs User.create! for Devise Users

**Problem:** When creating seeded or demo users with Devise, using `User.create!` triggers ActiveRecord callbacks including Devise's `send_confirmation_instructions` callback, which sends confirmation emails even when `confirmed_at` is already set.

**Solution:** Use `User.insert` to skip all ActiveRecord callbacks, including Devise's email-sending callbacks. This requires manually setting all required fields including `encrypted_password`, `role`, timestamps, and `confirmed_at`.

**Code Example:**
```ruby
# Skip Devise callbacks by using insert instead of create!
User.insert({
  email: 'admin@oroshi.local',
  username: 'admin',
  encrypted_password: Devise::Encryptor.digest(User, 'password123'),
  role: User.roles[:admin],          # Use enum integer value
  confirmed_at: Time.current,
  created_at: Time.current,
  updated_at: Time.current
})
```

**Gotcha:** `User.insert` returns the number of inserted rows, not the User object. If you need the created user, query for it afterward. Also, enum fields must use their integer values (e.g., `User.roles[:admin]`).

**Related:** `bin/sandbox` lines 391-419, `db/seeds.rb`

---

## Turbo & Stimulus

*Entries for Turbo Frames, Turbo Streams, Stimulus controllers, and Hotwire patterns.*

---

## Testing

*Entries for Test::Unit patterns, system tests, factories, and test setup.*

---

## Database & Migrations

*Entries for multi-database setup, schema loading, and migration patterns.*

---

## Asset Pipeline

*Entries for Propshaft, importmap, Tailwind, and font handling.*

---

## Internationalization

*Entries for i18n patterns, Japanese-first UI, and locale files.*

---

## Authentication & Authorization

*Entries for Devise configuration, user model patterns, and access control.*

---

## Background Jobs

*Entries for Solid Queue patterns, job configuration, and recurring tasks.*

---

*Last Updated: January 25, 2026*
