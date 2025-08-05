class AddOpeningDateToImports < ActiveRecord::Migration[7.2]
  def change
    add_column :imports, :opening_date_col_label, :string
    add_column :import_rows, :opening_date, :string
  end
end
