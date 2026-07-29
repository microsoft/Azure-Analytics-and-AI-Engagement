using System;
using System.Collections.Generic;
using System.Linq;
using PharmacyLegacy.Models;

namespace PharmacyLegacy.Data
{
    public static class DbSeeder
    {
        public static void Seed()
        {
            using (var db = new PharmacyContext())
            {
                SeedMedications(db);
                SeedPatients(db);
                SeedOrders(db);
                SeedInventory(db);
            }
        }

        private static void SeedMedications(PharmacyContext db)
        {
            if (db.Medications.Any()) return;
            db.Medications.AddRange(new[]
            {
                new Medication { Name = "Panadol Extra",     GenericName = "Paracetamol",      Category = "Pain Relief",    DosageForm = "Tablet",              Strength = "500mg",  Manufacturer = "GSK",        Description = "Fast relief from headaches and fever.",                    Price = 4.99m,   Stock = 200, RequiresPrescription = false },
                new Medication { Name = "Amoxil",            GenericName = "Amoxicillin",       Category = "Antibiotics",    DosageForm = "Capsule",             Strength = "500mg",  Manufacturer = "Pfizer",     Description = "Broad-spectrum antibiotic for bacterial infections.",      Price = 12.99m,  Stock = 150, RequiresPrescription = true  },
                new Medication { Name = "Vitamin C 1000",    GenericName = "Ascorbic Acid",     Category = "Vitamins",       DosageForm = "Effervescent Tablet", Strength = "1000mg", Manufacturer = "Bayer",      Description = "Immune support and antioxidant protection.",               Price = 7.49m,   Stock = 300, RequiresPrescription = false },
                new Medication { Name = "Brufen",            GenericName = "Ibuprofen",         Category = "Pain Relief",    DosageForm = "Tablet",              Strength = "400mg",  Manufacturer = "Abbott",     Description = "Anti-inflammatory for pain and fever.",                    Price = 5.99m,   Stock = 175, RequiresPrescription = false },
                new Medication { Name = "Actifed",           GenericName = "Triprolidine/Pseudoephedrine", Category = "Cold & Flu", DosageForm = "Tablet",   Strength = "2.5/60mg",Manufacturer = "Johnson",    Description = "Relief from cold and flu symptoms.",                       Price = 6.49m,   Stock = 120, RequiresPrescription = false },
                new Medication { Name = "Glucophage",        GenericName = "Metformin",         Category = "Diabetes Care",  DosageForm = "Tablet",              Strength = "500mg",  Manufacturer = "Merck",      Description = "Controls blood sugar in type 2 diabetes.",                 Price = 9.99m,   Stock = 100, RequiresPrescription = true  },
                new Medication { Name = "Lipitor",           GenericName = "Atorvastatin",      Category = "Heart Health",   DosageForm = "Tablet",              Strength = "20mg",   Manufacturer = "Pfizer",     Description = "Lowers cholesterol and protects heart health.",            Price = 24.99m,  Stock = 90,  RequiresPrescription = true  },
                new Medication { Name = "Zyrtec",            GenericName = "Cetirizine",        Category = "Cold & Flu",     DosageForm = "Tablet",              Strength = "10mg",   Manufacturer = "UCB",        Description = "24-hour non-drowsy allergy relief.",                       Price = 11.99m,  Stock = 160, RequiresPrescription = false },
                new Medication { Name = "Aspirin Cardio",    GenericName = "Acetylsalicylic Acid", Category = "Heart Health", DosageForm = "Enteric-Coated Tablet", Strength = "100mg", Manufacturer = "Bayer",   Description = "Low-dose aspirin for cardiovascular protection.",          Price = 8.99m,   Stock = 200, RequiresPrescription = false },
                new Medication { Name = "Caltrate Plus",     GenericName = "Calcium Carbonate", Category = "Vitamins",       DosageForm = "Tablet",              Strength = "600mg",  Manufacturer = "Pfizer",     Description = "Calcium and Vitamin D supplement for bone health.",        Price = 14.99m,  Stock = 130, RequiresPrescription = false },
                new Medication { Name = "Betadine",          GenericName = "Povidone-Iodine",   Category = "First Aid",      DosageForm = "Solution",            Strength = "10%",    Manufacturer = "Mundipharma",Description = "Topical antiseptic for wound care.",                       Price = 6.99m,   Stock = 200, RequiresPrescription = false },
                new Medication { Name = "Canesten",          GenericName = "Clotrimazole",      Category = "Skin Care",      DosageForm = "Cream",               Strength = "1%",     Manufacturer = "Bayer",      Description = "Antifungal cream for skin infections.",                    Price = 9.49m,   Stock = 110, RequiresPrescription = false },
                new Medication { Name = "Nexium",            GenericName = "Esomeprazole",      Category = "Digestive Health", DosageForm = "Capsule",           Strength = "20mg",   Manufacturer = "AstraZeneca",Description = "Proton pump inhibitor for acid reflux and ulcers.",        Price = 18.99m,  Stock = 95,  RequiresPrescription = true  },
                new Medication { Name = "Omega-3 Fish Oil",  GenericName = "Omega-3 Fatty Acids", Category = "Vitamins",     DosageForm = "Soft Gel",            Strength = "1000mg", Manufacturer = "Nature Made",Description = "Supports heart health and reduces inflammation.",           Price = 16.99m,  Stock = 180, RequiresPrescription = false },
                new Medication { Name = "Lantus SoloStar",   GenericName = "Insulin Glargine",  Category = "Diabetes Care",  DosageForm = "Injection",           Strength = "100U/mL",Manufacturer = "Sanofi",     Description = "Long-acting insulin for type 1 and type 2 diabetes.",      Price = 89.99m,  Stock = 60,  RequiresPrescription = true  }
            });
            db.SaveChanges();
        }

        private static void SeedPatients(PharmacyContext db)
        {
            if (db.Patients.Any()) return;
            db.Patients.AddRange(new[]
            {
                new Patient { FirstName = "Alice",   LastName = "Johnson",  Email = "alice.johnson@email.com",  Phone = "555-0101", Address = "123 Maple St",    City = "Seattle",     State = "WA", ZipCode = "98101", DateOfBirth = new DateTime(1985, 3, 14) },
                new Patient { FirstName = "Bob",     LastName = "Williams", Email = "bob.williams@email.com",   Phone = "555-0102", Address = "456 Oak Ave",     City = "Portland",    State = "OR", ZipCode = "97201", DateOfBirth = new DateTime(1972, 7, 22) },
                new Patient { FirstName = "Carol",   LastName = "Smith",    Email = "carol.smith@email.com",    Phone = "555-0103", Address = "789 Pine Rd",     City = "Denver",      State = "CO", ZipCode = "80201", DateOfBirth = new DateTime(1990, 11, 5) },
                new Patient { FirstName = "David",   LastName = "Brown",    Email = "david.brown@email.com",    Phone = "555-0104", Address = "321 Elm Blvd",    City = "Phoenix",     State = "AZ", ZipCode = "85001", DateOfBirth = new DateTime(1968, 1, 30) },
                new Patient { FirstName = "Emma",    LastName = "Davis",    Email = "emma.davis@email.com",     Phone = "555-0105", Address = "654 Cedar Ln",    City = "Chicago",     State = "IL", ZipCode = "60601", DateOfBirth = new DateTime(1995, 6, 18) },
                new Patient { FirstName = "Frank",   LastName = "Miller",   Email = "frank.miller@email.com",   Phone = "555-0106", Address = "987 Birch Dr",    City = "Houston",     State = "TX", ZipCode = "77001", DateOfBirth = new DateTime(1955, 9, 10) },
                new Patient { FirstName = "Grace",   LastName = "Wilson",   Email = "grace.wilson@email.com",   Phone = "555-0107", Address = "135 Walnut Way",  City = "Dallas",      State = "TX", ZipCode = "75201", DateOfBirth = new DateTime(1983, 4, 25) },
                new Patient { FirstName = "Henry",   LastName = "Moore",    Email = "henry.moore@email.com",    Phone = "555-0108", Address = "246 Spruce Ct",   City = "Atlanta",     State = "GA", ZipCode = "30301", DateOfBirth = new DateTime(1961, 12, 3) },
                new Patient { FirstName = "Irene",   LastName = "Taylor",   Email = "irene.taylor@email.com",   Phone = "555-0109", Address = "357 Poplar St",   City = "Miami",       State = "FL", ZipCode = "33101", DateOfBirth = new DateTime(1978, 8, 15) },
                new Patient { FirstName = "James",   LastName = "Anderson", Email = "james.anderson@email.com", Phone = "555-0110", Address = "468 Willow Ave",  City = "Los Angeles", State = "CA", ZipCode = "90001", DateOfBirth = new DateTime(1970, 2, 28) }
            });
            db.SaveChanges();
        }

        private static void SeedOrders(PharmacyContext db)
        {
            if (db.Orders.Any()) return;
            var patients    = db.Patients.ToList();
            var medications = db.Medications.ToList();
            if (!patients.Any() || !medications.Any()) return;

            var orders = new List<Order>
            {
                new Order { PatientId = patients[0].Id, OrderDate = DateTime.UtcNow.AddDays(-30), Status = "Delivered", PrescriptionVerified = true,  DeliveryAddress = patients[0].Address,
                    Items = new List<OrderItem> {
                        new OrderItem { MedicationId = medications[0].Id, Quantity = 2, UnitPrice = medications[0].Price },
                        new OrderItem { MedicationId = medications[7].Id, Quantity = 1, UnitPrice = medications[7].Price }
                    }
                },
                new Order { PatientId = patients[1].Id, OrderDate = DateTime.UtcNow.AddDays(-15), Status = "Shipped",   PrescriptionVerified = true,  DeliveryAddress = patients[1].Address,
                    Items = new List<OrderItem> {
                        new OrderItem { MedicationId = medications[1].Id, Quantity = 1, UnitPrice = medications[1].Price },
                        new OrderItem { MedicationId = medications[5].Id, Quantity = 1, UnitPrice = medications[5].Price }
                    }
                },
                new Order { PatientId = patients[2].Id, OrderDate = DateTime.UtcNow.AddDays(-7),  Status = "Processing", PrescriptionVerified = false, DeliveryAddress = patients[2].Address,
                    Items = new List<OrderItem> {
                        new OrderItem { MedicationId = medications[2].Id, Quantity = 2, UnitPrice = medications[2].Price },
                        new OrderItem { MedicationId = medications[9].Id, Quantity = 1, UnitPrice = medications[9].Price }
                    }
                },
                new Order { PatientId = patients[3].Id, OrderDate = DateTime.UtcNow.AddDays(-3),  Status = "Pending",    PrescriptionVerified = true,  DeliveryAddress = patients[3].Address,
                    Items = new List<OrderItem> {
                        new OrderItem { MedicationId = medications[6].Id, Quantity = 1, UnitPrice = medications[6].Price },
                        new OrderItem { MedicationId = medications[8].Id, Quantity = 2, UnitPrice = medications[8].Price }
                    }
                }
            };

            foreach (var o in orders)
            {
                o.TotalAmount = 0;
                foreach (var i in o.Items) o.TotalAmount += i.Quantity * i.UnitPrice;
            }

            db.Orders.AddRange(orders);
            db.SaveChanges();
        }

        private static void SeedInventory(PharmacyContext db)
        {
            if (db.Inventories.Any()) return;
            var medications = db.Medications.ToList();
            var locations   = new[] { "Shelf-A1", "Shelf-B2", "Shelf-C3", "Shelf-D4", "Refrigerator-R1" };
            for (int i = 0; i < medications.Count; i++)
            {
                db.Inventories.Add(new Inventory
                {
                    MedicationId     = medications[i].Id,
                    QuantityOnHand   = medications[i].Stock,
                    ReorderLevel     = 20,
                    ReorderQuantity  = 50,
                    StorageLocation  = locations[i % locations.Length],
                    LastUpdated      = DateTime.UtcNow
                });
            }
            db.SaveChanges();
        }
    }
}
