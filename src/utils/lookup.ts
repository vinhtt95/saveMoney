import { Account, Category } from '../types';

export function getCategoryById(categories: Category[], id: string): Category | undefined {
  return categories.find((c) => c.id === id);
}

export function getAccountById(accounts: Account[], id: string): Account | undefined {
  return accounts.find((a) => a.id === id);
}

export function categoryName(categories: Category[], id: string): string {
  return categories.find((c) => c.id === id)?.name ?? id;
}

export function accountName(accounts: Account[], id: string): string {
  return accounts.find((a) => a.id === id)?.name ?? id;
}

/** Find a category ID by its name (case-sensitive). Returns undefined if not found. */
export function getCategoryIdByName(categories: Category[], name: string): string | undefined {
  return categories.find((c) => c.name === name)?.id;
}

/** Find an account ID by its name (case-sensitive). Returns undefined if not found. */
export function getAccountIdByName(accounts: Account[], name: string): string | undefined {
  return accounts.find((a) => a.name === name)?.id;
}
