# ================================ Customizable Settings ================================
# ================================================================
# Product Discounts by Customer Tag
#
# If we have a matching customer (by tag), the entered discount
# will be applied to any matching items.
#
#   - 'customer_tag_match_type' determines whether we look for the customer
#     to be tagged with any of the entered tags or not. Can be:
#       - ':include' to check if the customer is tagged
#       - ':exclude' to make sure the customer isn't tagged
#   - 'customer_tags' is a list of tags to identify qualified
#     customers
#   - 'product_selector_match_type' determines whether we look for
#     products that do or don't match the entered selectors. Can
#     be:
#       - ':include' to check if the product does match
#       - ':exclude' to make sure the product doesn't match
#   - 'product_selector_type' determines how eligible products
#     will be identified. Can be either:
#       - ':tag' to find products by tag
#       - ':type' to find products by type
#       - ':vendor' to find products by vendor
#       - ':product_id' to find products by ID
#       - ':variant_id' to find products by variant ID
#       - ':subscription' to find subscription products
#       - ':all' for all products
#   - 'product_selectors' is a list of identifiers (from above)
#     for qualifying products. Product/Variant ID lists should
#     only contain numbers (ie. no quotes). If ':all' is used,
#     this can also be 'nil'.
#   - 'discount_type' is the type of discount to provide. Can be
#     either:
#       - ':percent'
#       - ':dollar'
#   - 'discount_amount' is the percentage/dollar discount to
#     apply (per item)
#   - 'discount_message' is the message to show when a discount
#     is applied
# ================================================================
DISCOUNTS_FOR_CUSTOMER_TAG = [
  {
    customer_tag_match_type: :include,
    customer_tags: ["5%US"],
    product_selector_match_type: :exclude,
    product_selector_type: :tag,
    product_selectors: ["non-discountable","uniforms15"],
    discount_type: :percent,
    discount_amount: 5,
    discount_message: "5% Loyalty Discount!",
  },
  {
    customer_tag_match_type: :include,
    customer_tags: ["10%US"],
    product_selector_match_type: :exclude,
    product_selector_type: :tag,
    product_selectors: ["non-discountable","uniforms15"],
    discount_type: :percent,
    discount_amount: 10,
    discount_message: "10% Loyalty Discount!",
  },
  {
    customer_tag_match_type: :include,
    customer_tags: ["15%US"],
    product_selector_match_type: :exclude,
    product_selector_type: :tag,
    product_selectors: ["non-discountable"],
    discount_type: :percent,
    discount_amount: 15,
    discount_message: "15% Loyalty Discount!",
  },
  {
    customer_tag_match_type: :include,
    customer_tags: ["18%US"],
    product_selector_match_type: :exclude,
    product_selector_type: :tag,
    product_selectors: ["non-discountable"],
    discount_type: :percent,
    discount_amount: 18,
    discount_message: "18% Loyalty Discount!",
  },
  {
    customer_tag_match_type: :include,
    customer_tags: ["20%US"],
    product_selector_match_type: :exclude,
    product_selector_type: :tag,
    product_selectors: ["non-discountable"],
    discount_type: :percent,
    discount_amount: 20,
    discount_message: "20% Loyalty Discount!",
  },
  {
    customer_tag_match_type: :include,
    customer_tags: ["22%US"],
    product_selector_match_type: :exclude,
    product_selector_type: :tag,
    product_selectors: ["non-discountable"],
    discount_type: :percent,
    discount_amount: 22,
    discount_message: "22% Loyalty Discount!",
  },
  {
    customer_tag_match_type: :include,
    customer_tags: ["25%US"],
    product_selector_match_type: :exclude,
    product_selector_type: :tag,
    product_selectors: ["non-discountable"],
    discount_type: :percent,
    discount_amount: 25,
    discount_message: "25% Loyalty Discount!",
  },
]
PRODUCT_DISCOUNT_TIERS = [
  {
    product_selector_match_type: :exclude,
    product_selector_type: :tag,
    product_selectors: ["non-discountable", "Sale"],
    tiers: [
      {
        threshold: 250,
        volume_discount_type: :percent,
        volume_discount_amount: 5,
        volume_discount_message: 'Spend $250 or more, and get 5% off!',
      },
      {
        threshold: 500,
        volume_discount_type: :percent,
        volume_discount_amount: 10,
        volume_discount_message: 'Spend $500 or more, and get 10% off!',
      },
      {
        threshold: 1000,
        volume_discount_type: :percent,
        volume_discount_amount: 15,
        volume_discount_message: 'Spend $1000 or more, and get 10% off!',
      },
    ],
  },
]

# ================================ Script Code (do not edit) ================================
# ================================================================
# CustomerTagSelector
#
# Finds whether the supplied customer has any of the entered tags.
# ================================================================
class CustomerTagSelector
  def initialize(match_type, tags)
    @comparator = match_type == :include ? 'any?' : 'none?'
    @tags = tags.map { |tag| tag.downcase.strip }
  end

  def match?(customer)
    customer_tags = customer.tags.map { |tag| tag.downcase.strip }
    (@tags & customer_tags).send(@comparator)
  end
end

# ================================================================
# ProductSelector
#
# Finds matching products by the entered criteria.
# ================================================================
class ProductSelector
  def initialize(match_type, selector_type, selectors)
    @match_type = match_type
    @comparator = match_type == :include ? 'any?' : 'none?'
    @selector_type = selector_type
    @selectors = selectors
  end

  def match?(line_item)
    if self.respond_to?(@selector_type)
      self.send(@selector_type, line_item)
    else
      raise RuntimeError.new('Invalid product selector type')
    end
  end

  def tag(line_item)
    product_tags = line_item.variant.product.tags.map { |tag| tag.downcase.strip }
    @selectors = @selectors.map { |selector| selector.downcase.strip }
    (@selectors & product_tags).send(@comparator)
  end

  def type(line_item)
    @selectors = @selectors.map { |selector| selector.downcase.strip }
    (@match_type == :include) == @selectors.include?(line_item.variant.product.product_type.downcase.strip)
  end

  def vendor(line_item)
    @selectors = @selectors.map { |selector| selector.downcase.strip }
    (@match_type == :include) == @selectors.include?(line_item.variant.product.vendor.downcase.strip)
  end

  def product_id(line_item)
    (@match_type == :include) == @selectors.include?(line_item.variant.product.id)
  end

  def variant_id(line_item)
    (@match_type == :include) == @selectors.include?(line_item.variant.id)
  end

  def subscription(line_item)
    !line_item.selling_plan_id.nil?
  end

  def all(line_item)
    true
  end
end

# ================================================================
# DiscountApplicator
#
# Applies the entered discount to the supplied line item.
# ================================================================
class DiscountApplicator
  def initialize(discount_type, discount_amount, discount_message,volume_discount_type,volume_discount_amount,volume_discount_message)
    @discount_type = discount_type
    @discount_message = discount_message
    @volume_discount_type = volume_discount_type
    @volume_discount_message = volume_discount_message

    @discount_amount = if discount_type == :percent
      1 - (discount_amount * 0.01)
    else
      Money.new(cents: 100) * discount_amount
    end
  end

    @volume_discount_amount = if volume_discount_type == :percent
    1 - (volume_discount_amount * 0.01)
  else
    Money.new(cents: 100) * volume_discount_amount
  end
end


  def apply(line_item)
    new_line_price = if @discount_type == :percent
      line_item.line_price * @discount_amount
    else
      [line_item.line_price - (@discount_amount * line_item.quantity), Money.zero].max
    end

    line_item.change_line_price(new_line_price, message: @discount_message)
  end


  def apply(line_item)
    new_line_price = if @volume_discount_amount == :percent
        line_item.line_price * @volume_discount_amount
    else
        [line_item.line_price - (@volume_discount_amount * line_item.quantity), Money.zero].max
    end
    line_item.change_line_price(new_line_price, message: @discount_message)
end

# ================================================================
# VolumeDiscountApplicator
#
# Applies the entered discount to the supplied line item.
# ================================================================
class VolumeDiscountApplicator
    def initialize(volume_discount_type, volume_discount_amount, volume_discount_message)
      @volume_discount_type = volume_discount_type
      @volume_discount_message = volume_discount_message
  
      @volume_discount_amount = if volume_discount_type == :percent
        1 - (volume_discount_amount * 0.01)
      else
        Money.new(cents: 100) * volume_discount_amount
      end
    end
  
    def apply(line_item)
      new_line_price = if @volume_discount_type == :percent
        line_item.line_price * @volume_discount_amount
      else
        [line_item.line_price - (@volume_discount_amount * line_item.quantity), Money.zero].max
      end
  
      line_item.change_line_price(new_line_price, message: @volume_discount_message)
    end
  end

# ================================================================
# DiscountForCustomerTagCampaign
#
# If we have a matching customer (by tag), the entered discount
# is applied to any matching items.
# ================================================================


class DiscountForCustomerTagCampaign
  def initialize(campaigns)
    @campaigns = campaigns
  end

  def run(cart)
    return unless cart.customer&.tags

    @campaigns.each do |campaign|
      customer_tag_selector = CustomerTagSelector.new(campaign[:customer_tag_match_type], campaign[:customer_tags])

      next unless customer_tag_selector.match?(cart.customer)

      product_selector = ProductSelector.new(
        campaign[:product_selector_match_type],
        campaign[:product_selector_type],
        campaign[:product_selectors]
      )

      discount_applicator = DiscountApplicator.new(
        campaign[:discount_type],
        campaign[:discount_amount],
        campaign[:discount_message]
      )

      cart.line_items.each do |line_item|
        next unless product_selector.match?(line_item)
        discount_applicator.apply(line_item)
      end
    end
  end
end

# ================================================================
# TieredProductDiscountByProductSpendCampaign
#
# If the total amount spent on matching items is greather than (or
# equal to) an entered threshold, the associated discount is
# applied to each matching item.
# ================================================================
class TieredProductDiscountByProductSpendCampaign
    def initialize(campaigns)
      @campaigns = campaigns
    end
  
    def run(cart)
      return unless cart.customer&.tags

      @campaigns.each do |campaign|

        customer_tag_selector = CustomerTagSelector.new(campaign[:customer_tag_match_type], campaign[:customer_tags])

        next unless customer_tag_selector.match?(cart.customer)

        if campaign[:product_selector_type] == :all
          total_applicable_cost = cart.subtotal_price
          applicable_items = cart.line_items
        else
          product_selector = ProductSelector.new(
            campaign[:product_selector_match_type],
            campaign[:product_selector_type],
            campaign[:product_selectors],
          )
  
          applicable_items = cart.line_items.select { |line_item| product_selector.match?(line_item) }
  
          next if applicable_items.nil?
  
          total_applicable_cost = applicable_items.map(&:line_price).reduce(Money.zero, :+)
        end
  
        tiers = campaign[:tiers].sort_by { |tier| tier[:threshold] }.reverse
        applicable_tier = tiers.find { |tier|  total_applicable_cost >= (Money.new(cents: 100) * tier[:threshold]) }
  
        next if applicable_tier.nil?
  
        discount_applicator = DiscountApplicator.new(
          applicable_tier[:volume_discount_type],
          applicable_tier[:volume_discount_amount],
          applicable_tier[:volume_discount_message]
        )
  
        applicable_items.each do |line_item|
          discount_applicator.apply(line_item)
        end
      end
    end
  end

CAMPAIGNS = [
  DiscountForCustomerTagCampaign.new(DISCOUNTS_FOR_CUSTOMER_TAG),
  TieredProductDiscountByProductSpendCampaign.new(PRODUCT_DISCOUNT_TIERS),
]

CAMPAIGNS.each do |campaign|
  campaign.run(Input.cart)
end

Output.cart = Input.cart