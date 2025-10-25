class CreatePriorAccounts < ActiveRecord::Migration[7.2]
  def change
    create_table :prior_accounts, id: :uuid do |t|
      t.string :account_number
      t.string :name, null: false
      t.string :currency, null: false
      t.decimal :current_balance, precision: 19, scale: 4
      t.date :last_statement_date
      t.datetime :last_synced_at
      t.jsonb :raw_payload, default: {}
      t.jsonb :raw_transactions_payload, default: {}
      t.jsonb :sync_metadata, default: {}

      t.timestamps
    end

    add_index :prior_accounts, :name, unique: true
    add_index :prior_accounts, :account_number, unique: true, where: "account_number IS NOT NULL"
    add_reference :accounts, :prior_account, foreign_key: true, type: :uuid
  end
end
