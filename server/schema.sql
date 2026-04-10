CREATE DATABASE IF NOT EXISTS savemoney_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE savemoney_db;

CREATE TABLE IF NOT EXISTS categories (
  id    VARCHAR(36)              NOT NULL PRIMARY KEY,
  name  VARCHAR(255)             NOT NULL,
  type  ENUM('Expense','Income') NOT NULL,
  icon  VARCHAR(50)              NOT NULL DEFAULT 'tag.fill', -- Thêm cột icon
  color VARCHAR(20)              NOT NULL DEFAULT 'accent'    -- Thêm cột color
);

CREATE TABLE IF NOT EXISTS accounts (
  id    VARCHAR(36)  NOT NULL PRIMARY KEY,
  name  VARCHAR(255) NOT NULL,
  icon  VARCHAR(50)  NOT NULL DEFAULT 'creditcard.fill',
  color VARCHAR(20)  NOT NULL DEFAULT 'accent'
);

CREATE TABLE IF NOT EXISTS account_balances (
  account_id VARCHAR(36)   NOT NULL PRIMARY KEY,
  balance    DECIMAL(18,2) NOT NULL DEFAULT 0,
  FOREIGN KEY (account_id) REFERENCES accounts(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS transactions (
  id             VARCHAR(36)                                      NOT NULL PRIMARY KEY,
  date           DATE                                             NOT NULL,
  type           ENUM('Expense','Income','Account','Transfer')    NOT NULL,
  category_id    VARCHAR(36)                                      NULL,
  account_id     VARCHAR(36)                                      NOT NULL,
  transfer_to_id VARCHAR(36)                                      NULL,
  amount         DECIMAL(18,2)                                    NOT NULL,
  note           TEXT                                             NULL,
  FOREIGN KEY (category_id)    REFERENCES categories(id) ON DELETE SET NULL,
  FOREIGN KEY (account_id)     REFERENCES accounts(id)   ON DELETE RESTRICT,
  FOREIGN KEY (transfer_to_id) REFERENCES accounts(id)   ON DELETE SET NULL,
  INDEX idx_date (date)
);

CREATE TABLE IF NOT EXISTS budgets (
  id           VARCHAR(36)   NOT NULL PRIMARY KEY,
  name         VARCHAR(255)  NOT NULL,
  limit_amount DECIMAL(18,2) NOT NULL,
  date_start   DATE          NOT NULL,
  date_end     DATE          NOT NULL
);

CREATE TABLE IF NOT EXISTS budget_categories (
  budget_id   VARCHAR(36) NOT NULL,
  category_id VARCHAR(36) NOT NULL,
  PRIMARY KEY (budget_id, category_id),
  FOREIGN KEY (budget_id)   REFERENCES budgets(id)    ON DELETE CASCADE,
  FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS gold_assets (
  id           VARCHAR(36)   NOT NULL PRIMARY KEY,
  brand        VARCHAR(20)   NOT NULL,
  product_id   VARCHAR(100)  NULL,
  product_name VARCHAR(255)  NOT NULL,
  quantity     DECIMAL(10,4) NOT NULL,
  note         TEXT          NULL,
  created_at   VARCHAR(50)   NOT NULL
);

CREATE TABLE IF NOT EXISTS user_settings (
  `key` VARCHAR(100) NOT NULL PRIMARY KEY,
  value TEXT         NOT NULL
);
