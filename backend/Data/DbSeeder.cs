using PartsUnitBacked.Models;

namespace PartsUnitBacked.Data
{
    public static class DbSeeder
    {
        public static void Seed(AppDbContext context)
        {
            if (!context.Products.Any())
            {
                context.Products.AddRange(
                    new Product { Name = "Engine Oil - Castrol GTX Motor Oil 5W-30", Category = "Engine Oil", Description = "Premium conventional motor oil that provides superior protection against viscosity and thermal breakdown.", Price = 24.99m, Stock = 100, ImageUrl = "https://pensol.com/img/pxt_pride.jpg" },
                    new Product { Name = "Brake Pads - ACDelco Professional", Category = "Brake Parts", Description = "High-performance brake pads designed for superior stopping power and extended pad life.", Price = 89.99m, Stock = 100, ImageUrl = "https://images.pexels.com/photos/190574/pexels-photo-190574.jpeg?auto=compress&cs=tinysrgb&w=500" },
                    new Product { Name = "Spark Plugs - NGK Set of 4", Category = "Ignition", Description = "Premium spark plugs engineered for optimal performance, fuel efficiency, and long life.", Price = 32.99m, Stock = 100, ImageUrl = "https://images.pexels.com/photos/3807277/pexels-photo-3807277.jpeg?auto=compress&cs=tinysrgb&w=500" },
                    new Product { Name = "Wiper Blades - Bosch Pair", Category = "Exterior", Description = "All-weather wiper blades with dual rubber compounds for streak-free wiping in all conditions.", Price = 19.99m, Stock = 100, ImageUrl = "https://www.vtlworld.in/cdn/shop/files/81i2juQ8rWL._SL1500.jpg?v=1699696722&width=1946" },
                    new Product { Name = "Transmission Fluid - Valvoline MaxLife", Category = "Transmission", Description = "Full synthetic transmission fluid designed for high-mileage vehicles with seal conditioners.", Price = 34.99m, Stock = 0, ImageUrl = "https://www.mobil.com/lubricants/-/media/project/wep/mobil/mobil-row-us-1/automatic-transmission-fluid-synthetic-grouping-2020/automatic-transmission-fluid-synthetic-grouping-2020-fb-og.jpg" },
                    new Product { Name = "Tires - Michelin Defender T+H", Category = "Tires", Description = "All-season touring tire with MaxTouch Construction for longer tread life and fuel efficiency.", Price = 129.99m, Stock = 100, ImageUrl = "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQzWjFxegUOy40rbRPk_NaWx7U9zGWOJ1PGQA&s" },
                    new Product { Name = "Battery - Optima RedTop", Category = "Electrical", Description = "High-performance AGM battery with exceptional starting power and deep-cycle capability.", Price = 199.99m, Stock = 100, ImageUrl = "https://p.kindpng.com/picc/s/137-1372233_battery-png-image-transparent-background-exide-battery-images.png" },
                    new Product { Name = "Oil Filter - Mobil 1 Extended Performance", Category = "Engine Oil", Description = "Advanced synthetic oil filter for long-lasting engine protection and performance.", Price = 15.99m, Stock = 100, ImageUrl = "https://www.shutterstock.com/image-illustration/motor-oil-canisters-car-filter-260nw-1180984981.jpg" },
                    new Product { Name = "Headlight Bulbs - Philips X-tremeVision", Category = "Electrical", Description = "High-performance halogen headlight bulbs for maximum visibility and safety.", Price = 39.99m, Stock = 100, ImageUrl = "https://i.ebayimg.com/images/g/sQoAAOSwcRBkiShG/s-l1200.jpg" },
                    new Product { Name = "Wiper Blades - Rain-X Latitude", Category = "Exterior", Description = "Premium wiper blades with water-repellent coating for streak-free performance.", Price = 22.99m, Stock = 100, ImageUrl = "https://www.boschaftermarket.com/xrm/media/images/country_specific/in/parts_11/wipers/bosch_aerotwin_universal_ap_flat_wiper_blade_res_800x450.webp" },
                    new Product { Name = "Brake Rotor - Bosch QuietCast Premium", Category = "Brake Parts", Description = "Precision-balanced brake rotor for smooth, quiet braking and long life.", Price = 74.99m, Stock = 500, ImageUrl = "https://t3.ftcdn.net/jpg/04/91/72/40/360_F_491724099_KNhoJGIawrr9FDPkeCAeTrLlxvA7hXEk.jpg" },
                    new Product { Name = "Tires - Goodyear Assurance All-Season", Category = "Tires", Description = "Reliable all-season tire with enhanced traction and long tread life.", Price = 119.99m, Stock = 100, ImageUrl = "https://media.istockphoto.com/id/994415414/photo/car-wheel-set.jpg?s=612x612&w=0&k=20&c=IyaV9jxoaGUwNU8dWLsPofSNqSgxBJlorngVC1k5gpw=" },
                    new Product { Name = "Spark Plug - Denso Iridium TT", Category = "Ignition", Description = "Iridium spark plug for improved ignition efficiency and fuel economy.", Price = 13.99m, Stock = 100, ImageUrl = "https://www.partspro.ph/cdn/shop/products/Standard_e795d2ad-c6b3-4ec8-8f28-ea9966921ae3.jpg?v=1552880792" },
                    new Product { Name = "Battery - DieHard Platinum AGM", Category = "Electrical", Description = "Premium AGM battery with high cold cranking amps and long service life.", Price = 229.99m, Stock = 100, ImageUrl = "https://spn-sta.spinny.com/blog/20220921165654/SLI-edited-scaled.webp?compress=true&quality=80&w=732&dpr=2.6" },
                    new Product { Name = "Whispering Blue", Category = "Zava", Description = "Imagine a gentle breeze carrying the soft hues of a whispering blue, reminiscent of a tranquil sky at dawn.", Price = 47.99m, Stock = 100, ImageUrl = "https://dreamdemoassets.blob.core.windows.net/herodemos/furniturehardwoodflooragainstbluewallV1.png" },
                    new Product { Name = "Vibrant Sunshine Yellow", Category = "Zava", Description = "Imagine a sunshine yellow hue that wraps around you like a warm summer, reminiscent of a serene summer morning.", Price = 15.99m, Stock = 100, ImageUrl = "https://dreamdemoassets.blob.core.windows.net/herodemos/closeupspraybottle_v1.png" },
                    new Product { Name = "Frosted Blue", Category = "Zava", Description = "Imagine a frosted blue hue that wraps around you like a cool breeze, reminiscent of a serene winter morning.", Price = 46.99m, Stock = 100, ImageUrl = "https://staidemodev.blob.core.windows.net/hero-demos-hardcoded-chat-images/figmaimages/Frosted%20Blue.png" },
                    new Product { Name = "Effervescent Jade, Interior Wall Paint, 1 gallon bucket", Category = "Zava", Description = "OM-403 A sparkling, uplifting jade green for spaces brimming with vitality.", Price = 75.99m, Stock = 100, ImageUrl = "https://staidemodev.blob.core.windows.net/hero-demos-hardcoded-chat-images/figmaimages/jade-color-interior-design.png" }
                );
                context.SaveChanges();
            }
        }
    }
} 