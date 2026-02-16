-- Create treatment table for storing plant disease treatment information
-- Run this SQL in your Supabase SQL Editor

CREATE TABLE IF NOT EXISTS public.treatment (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    plant_name TEXT NOT NULL,
    disease_name TEXT NOT NULL,
    treatment_suggestions TEXT[] NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(plant_name, disease_name)
);

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_treatment_plant_name ON public.treatment(plant_name);
CREATE INDEX IF NOT EXISTS idx_treatment_disease_name ON public.treatment(disease_name);

-- Enable Row Level Security
ALTER TABLE public.treatment ENABLE ROW LEVEL SECURITY;

-- Create policy to allow all users to read treatment data
CREATE POLICY "Allow public read access to treatment"
    ON public.treatment
    FOR SELECT
    TO public
    USING (true);

-- Optional: Create policy for authenticated users to insert/update
CREATE POLICY "Allow authenticated users to insert treatment"
    ON public.treatment
    FOR INSERT
    TO authenticated
    WITH CHECK (true);

CREATE POLICY "Allow authenticated users to update treatment"
    ON public.treatment
    FOR UPDATE
    TO authenticated
    USING (true)
    WITH CHECK (true);

-- Insert treatment data from JSON
INSERT INTO public.treatment (plant_name, disease_name, treatment_suggestions) VALUES
('Apple', 'Apple_scab', ARRAY['Remove and destroy fallen leaves to prevent fungal spread.', 'Apply fungicides like captan or myclobutanil during early growth.', 'Prune trees to improve air circulation.', 'Avoid overhead watering.', 'Plant resistant apple varieties when possible.']),
('Apple', 'Black_rot', ARRAY['Prune infected branches and remove mummified fruits.', 'Apply copper-based fungicides.', 'Disinfect pruning tools after use.', 'Maintain proper tree spacing.', 'Remove dead wood regularly.']),
('Apple', 'Cedar_apple_rust', ARRAY['Remove nearby cedar or juniper hosts if possible.', 'Use preventive fungicide sprays in spring.', 'Plant resistant cultivars.', 'Improve airflow through pruning.', 'Monitor trees regularly for early signs.']),
('Cherry (including_sour)', 'Powdery_mildew', ARRAY['Apply sulfur-based fungicides.', 'Ensure good air circulation around plants.', 'Avoid excessive nitrogen fertilizers.', 'Remove infected leaves promptly.', 'Water plants at the base to keep foliage dry.']),
('Corn (maize)', 'Cercospora_leaf_spot Gray_leaf_spot', ARRAY['Use resistant corn hybrids.', 'Rotate crops yearly.', 'Apply foliar fungicides when disease risk is high.', 'Remove crop residues after harvest.', 'Avoid dense planting.']),
('Corn (maize)', 'Common_rust_', ARRAY['Plant resistant varieties.', 'Apply fungicides if infection is severe.', 'Monitor fields regularly.', 'Maintain balanced fertilization.', 'Avoid late planting.']),
('Corn (maize)', 'Northern_Leaf_Blight', ARRAY['Use resistant hybrids.', 'Practice crop rotation.', 'Apply fungicides early if detected.', 'Remove infected debris.', 'Ensure proper plant spacing.']),
('Grape', 'Black_rot', ARRAY['Remove infected berries and leaves.', 'Apply fungicides from early season.', 'Prune vines to improve airflow.', 'Keep the vineyard clean.', 'Avoid overhead irrigation.']),
('Grape', 'Esca_(Black_Measles)', ARRAY['Remove and destroy infected wood.', 'Protect pruning wounds with sealant.', 'Avoid excessive irrigation.', 'Maintain vine health with balanced nutrients.', 'Replant severely affected vines.']),
('Grape', 'Leaf_blight_(Isariopsis_Leaf_Spot)', ARRAY['Apply recommended fungicides.', 'Remove infected leaves.', 'Improve air circulation.', 'Avoid wet foliage.', 'Use disease-free planting material.']),
('Orange', 'Haunglongbing_(Citrus_greening)', ARRAY['Remove infected trees immediately.', 'Control psyllid insects using insecticides.', 'Use certified disease-free plants.', 'Apply balanced fertilizers.', 'Monitor orchards frequently.']),
('Peach', 'Bacterial_spot', ARRAY['Apply copper sprays during dormancy.', 'Plant resistant varieties.', 'Avoid overhead irrigation.', 'Prune infected branches.', 'Ensure good airflow.']),
('Pepper, bell', 'Bacterial_spot', ARRAY['Use certified disease-free seeds.', 'Apply copper-based bactericides.', 'Rotate crops every season.', 'Avoid working with wet plants.', 'Remove infected plants quickly.']),
('Potato', 'Early_blight', ARRAY['Apply fungicides like chlorothalonil.', 'Rotate crops for 2–3 years.', 'Remove infected foliage.', 'Maintain proper plant nutrition.', 'Avoid overhead watering.']),
('Potato', 'Late_blight', ARRAY['Use certified disease-free seed potatoes.', 'Apply preventive fungicides.', 'Destroy infected plants immediately.', 'Improve field drainage.', 'Avoid excess moisture.']),
('Squash', 'Powdery_mildew', ARRAY['Apply sulfur or potassium bicarbonate sprays.', 'Provide adequate plant spacing.', 'Remove infected leaves.', 'Avoid excess nitrogen fertilizer.', 'Plant resistant varieties.']),
('Strawberry', 'Leaf_scorch', ARRAY['Remove infected leaves.', 'Apply appropriate fungicides.', 'Improve air circulation.', 'Avoid overhead irrigation.', 'Use healthy transplants.']),
('Tomato', 'Bacterial_spot', ARRAY['Use disease-free seeds.', 'Apply copper sprays.', 'Rotate crops regularly.', 'Avoid handling wet plants.', 'Remove infected debris.']),
('Tomato', 'Early_blight', ARRAY['Apply fungicides promptly.', 'Stake plants to improve airflow.', 'Remove lower infected leaves.', 'Mulch soil to prevent splash.', 'Rotate crops yearly.']),
('Tomato', 'Late_blight', ARRAY['Use resistant varieties.', 'Apply preventive fungicides.', 'Remove infected plants immediately.', 'Avoid overhead watering.', 'Ensure good spacing.']),
('Tomato', 'Leaf_Mold', ARRAY['Improve greenhouse ventilation.', 'Reduce humidity levels.', 'Apply fungicides when necessary.', 'Avoid wetting leaves.', 'Use resistant varieties.']),
('Tomato', 'Septoria_leaf_spot', ARRAY['Remove infected leaves.', 'Apply fungicides early.', 'Mulch to prevent soil splash.', 'Rotate crops.', 'Avoid overhead watering.']),
('Tomato', 'Spider_mites Two-spotted_spider_mite', ARRAY['Spray plants with strong water to remove mites.', 'Use insecticidal soap or neem oil.', 'Introduce natural predators like ladybugs.', 'Maintain adequate humidity.', 'Remove heavily infested leaves.']),
('Tomato', 'Target_Spot', ARRAY['Apply recommended fungicides.', 'Improve air circulation.', 'Avoid leaf wetness.', 'Remove infected plant material.', 'Practice crop rotation.']),
('Tomato', 'Tomato_mosaic_virus', ARRAY['Remove infected plants immediately.', 'Disinfect gardening tools.', 'Avoid tobacco use near plants.', 'Control aphids.', 'Plant resistant varieties.']),
('Tomato', 'Tomato_Yellow_Leaf_Curl_Virus', ARRAY['Control whiteflies using insecticides or traps.', 'Remove infected plants.', 'Use virus-resistant varieties.', 'Install reflective mulches.', 'Maintain field sanitation.'])
ON CONFLICT (plant_name, disease_name) DO NOTHING;

-- Create function to auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to automatically update updated_at
CREATE TRIGGER update_treatment_updated_at
    BEFORE UPDATE ON public.treatment
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Grant necessary permissions
GRANT SELECT ON public.treatment TO anon;
GRANT SELECT ON public.treatment TO authenticated;
GRANT ALL ON public.treatment TO service_role;
