INSERT INTO vets (id, first_name, last_name) VALUES (1, 'James', 'Carter') ON CONFLICT (id) DO NOTHING;
INSERT INTO vets (id, first_name, last_name) VALUES (2, 'Helen', 'Leary') ON CONFLICT (id) DO NOTHING;
INSERT INTO vets (id, first_name, last_name) VALUES (3, 'Linda', 'Douglas') ON CONFLICT (id) DO NOTHING;
INSERT INTO vets (id, first_name, last_name) VALUES (4, 'Rafael', 'Ortega') ON CONFLICT (id) DO NOTHING;
INSERT INTO vets (id, first_name, last_name) VALUES (5, 'Henry', 'Stevens') ON CONFLICT (id) DO NOTHING;
INSERT INTO vets (id, first_name, last_name) VALUES (6, 'Sharon', 'Jenkins') ON CONFLICT (id) DO NOTHING;

INSERT INTO specialties (id, name) VALUES (1, 'radiology') ON CONFLICT (id) DO NOTHING;
INSERT INTO specialties (id, name) VALUES (2, 'surgery') ON CONFLICT (id) DO NOTHING;
INSERT INTO specialties (id, name) VALUES (3, 'dentistry') ON CONFLICT (id) DO NOTHING;

INSERT INTO vet_specialties (vet_id, specialty_id) VALUES (2, 1) ON CONFLICT (vet_id, specialty_id) DO NOTHING;
INSERT INTO vet_specialties (vet_id, specialty_id) VALUES (3, 2) ON CONFLICT (vet_id, specialty_id) DO NOTHING;
INSERT INTO vet_specialties (vet_id, specialty_id) VALUES (3, 3) ON CONFLICT (vet_id, specialty_id) DO NOTHING;
INSERT INTO vet_specialties (vet_id, specialty_id) VALUES (4, 2) ON CONFLICT (vet_id, specialty_id) DO NOTHING;
INSERT INTO vet_specialties (vet_id, specialty_id) VALUES (5, 1) ON CONFLICT (vet_id, specialty_id) DO NOTHING;
