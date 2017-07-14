class Product < ActiveRecord::Base
<<<<<<< HEAD
=======
  has_many :line_items, dependent: :destroy
  has_one :product_meta_tag, dependent: :destroy

>>>>>>> 1b3eb93... Add HasOne support as nested form (#801)
  validates :description, presence: true
  validates :image_url, presence: true
  validates :name, presence: true
  validates :price, presence: true
  validates :slug, uniqueness: true
  validate :valid_slug

  accepts_nested_attributes_for :product_meta_tag

  def name=(value)
    self.slug = value.to_s.parameterize
    super(value)
  end

  def to_param
    slug
  end

  def valid_slug
    if slug.blank?
      errors.add :name, "must have letters or numbers for the URL"
    end
  end
end
