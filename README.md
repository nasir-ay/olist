# Project 3: Late Deliveries and Review Scores (Olist)

![Dashboard](images/dashboard.png)

## Business question

Do late deliveries lower review scores, and where, in terms of state and product category, is the damage worst? Late deliveries can damage customer satisfaction, which may reduce repeat purchases and raise customer acquisition costs, making it important to identify where delivery problems are most severe. Using the Brazilian E-Commerce Public Dataset by Olist, which contains 99,441 orders from 2016 to 2018, I analyzed 96,470 delivered orders with an actual customer delivery date. In this analysis, an order counts as late if it arrived on a later calendar day than the estimated delivery date.

## Data and approach

I used six tables for the analysis: `orders`, `customers`, `order_reviews`, `order_items`, `products`, and `product_category_name_translation`. For orders that have more than one review, I used the latest review (by `review_answer_timestamp`, with ties broken by `review_id`), leaving only one review per `order_id`. Orders that were not delivered or were missing a delivered date were excluded (2,971) because lateness can't be measured without a delivered date, leaving 96,470 orders (99,441 minus 2,971) for analysis. I used MySQL for the analysis and connected MySQL views directly to Power BI for visualization. I used the `order_items` table for the category-based analysis, because an order can contain items from different categories, so category counts are items, not orders (110,189 items from the 96,470 orders). Items with no product category were assigned "unknown".

## Key findings

1. **Late orders score about 2 stars lower** than on-time orders (2.27 vs 4.29).
2. **The overall late rate is 6.8%**, with spikes in November 2017 (12.4%), February 2018 (14.1%), and March 2018 (19.0%).
3. **The damage is more concentrated in states like RJ and BA.** They combine late rates around 12% (about three times SP's 4.5%) with a meaningful number of late orders (1,495 and 396). SP has the most late orders but a low late rate, so its problem is volume, not a systemic delivery issue.
4. **Every category I analysed shows a gap of about 2 stars** between on-time and late items (19 categories with at least 100 late items; counts are items, not orders). The top five sit between 2.12 and 2.23, a spread of only 0.11:

   | Category | Score gap |
   |---|---|
   | toys | 2.23 |
   | fashion_bags_accessories | 2.16 |
   | baby | 2.16 |
   | sports_leisure | 2.13 |
   | perfumery | 2.12 |

   Lateness therefore affects every category by roughly the same amount, and no category is dramatically worse. Categories with fewer than 100 late items were excluded because their averages are too unstable to compare.

## Recommendations

1. **Investigate delivery partners in any state where the late rate exceeds 10%, starting with RJ and BA** (12.1% and 12.2%). These states combine high late rates with relatively large order volumes, so they offer the biggest gain.
2. **Monitor monthly late rates.** Rates above 7% should be closely monitored, and any month that crosses 10% should be escalated. Compare late rates by state within that month to find which states drive the spike.
3. **Check whether delivery estimates adjusted during the spike months.** November 2017 had 7,288 orders, up from 4,478 in October (about 63% more), and the late rate rose from 4.2% to 12.4%. However, February and March 2018 had volumes similar to January 2018 (5.7% late), so volume alone doesn't explain them. Compare the average days from purchase to the estimated date with the average days from purchase to actual delivery for these months. If the average days to the estimated date stay about the same across months, but the average days to actual delivery rise in months above 10% late, the estimates did not adjust. In that case, lengthen estimates for those periods.

## Limitations and data notes

- **Missing review record:** 99,223 rows were loaded into MySQL from `order_reviews`, compared with 99,224 in the CSV. I was unable to confirm the cause. It is one row (review_id `7bc2406110b926393aa56f80a40eba40`, order_id `73fc7af87114b39712e6da79b0a377eb`), about 0.001% of the rows, so it has no noticeable effect on the analysis.
- **Deduplication:** 551 extra reviews across 547 orders were removed; 202 of those orders had differing scores, so the latest-review rule affects about 0.2% of orders. I used the latest review because it reflects the customer's final opinion, and the share affected is small.
- **Association, not causation:** late orders score about 2 stars lower, but the data can't show that lateness is the cause, because other factors (product problems, seller quality) may also drive both.
- **2016 excluded from the monthly chart** because two of its three months have one order each.
- **States excluded from the state chart:** AC, AP, RR and AM, each with fewer than 150 orders.
- **Category analysis** counts order items and excludes categories with fewer than 100 late items.

## Next steps

- Obtain carrier-level data to test whether specific delivery providers drive late deliveries in RJ and BA.
