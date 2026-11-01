/// Short, general explanations of key nutrients: what they do for the body
/// (skin, hair, eyes, growth, energy) and where to find them.
/// General information only, not medical advice.
class NutrientInfo {
  final String name;
  final String emoji;
  final List<String> helps; // tags: Skin, Hair, Eyes, Growth, Energy...
  final String whatItDoes;
  final String lowSigns;
  final List<String> sources;
  final String dailyNeed;

  const NutrientInfo({
    required this.name,
    required this.emoji,
    required this.helps,
    required this.whatItDoes,
    required this.lowSigns,
    required this.sources,
    required this.dailyNeed,
  });
}

const nutrientGuide = <NutrientInfo>[
  NutrientInfo(
    name: 'Protein',
    emoji: '💪',
    helps: ['Growth', 'Muscle', 'Hair', 'Skin'],
    whatItDoes:
        'Provides the amino acids used to build and repair muscle, skin, hair '
        '(keratin) and enzymes. Teenagers need it for growth.',
    lowSigns: 'Slow recovery from exercise, muscle loss, brittle hair and nails.',
    sources: ['Eggs', 'Chicken', 'Fish & omena', 'Beans, ndengu, lentils',
        'Milk & yoghurt', 'Tofu'],
    dailyNeed: '≈0.8–1.0 g per kg of body weight; 1.6–2.0 g/kg if training hard.',
  ),
  NutrientInfo(
    name: 'Iron',
    emoji: '🩸',
    helps: ['Energy', 'Hair', 'Focus'],
    whatItDoes:
        'Part of haemoglobin, which carries oxygen in the blood. Low iron is one '
        'of the most common deficiencies worldwide.',
    lowSigns: 'Tiredness, pale skin, shortness of breath, hair shedding.',
    sources: ['Red meat & liver', 'Omena', 'Beans & lentils', 'Spinach & managu',
        'Fortified flour'],
    dailyNeed: '11 mg (boys 14–18), 15 mg (girls 14–18), 8–18 mg for adults. '
        'Eat it with vitamin C to absorb more.',
  ),
  NutrientInfo(
    name: 'Vitamin C',
    emoji: '🍊',
    helps: ['Skin', 'Immunity', 'Iron absorption'],
    whatItDoes:
        'Needed to make collagen, the protein that keeps skin firm and helps '
        'wounds heal. It also boosts iron absorption from plant foods.',
    lowSigns: 'Bleeding gums, slow-healing cuts, frequent colds.',
    sources: ['Oranges', 'Pawpaw', 'Mango', 'Pineapple', 'Kachumbari', 'Broccoli'],
    dailyNeed: '65–75 mg (teens), 75–90 mg (adults).',
  ),
  NutrientInfo(
    name: 'Vitamin A',
    emoji: '👁️',
    helps: ['Eyes', 'Skin', 'Immunity'],
    whatItDoes:
        'Forms the light-sensitive pigment in the retina and keeps skin and the '
        'lining of the eyes healthy.',
    lowSigns: 'Poor night vision, dry eyes, dry or rough skin.',
    sources: ['Carrots', 'Sweet potato (orange)', 'Mango & pawpaw', 'Sukuma & spinach',
        'Eggs', 'Liver'],
    dailyNeed: '≈700–900 µg RAE per day.',
  ),
  NutrientInfo(
    name: 'Zinc',
    emoji: '🧬',
    helps: ['Growth', 'Skin', 'Hair', 'Hormones'],
    whatItDoes:
        'Used by hundreds of enzymes; important for growth, wound healing, '
        'immunity and normal hormone production during puberty.',
    lowSigns: 'Slow growth, acne-prone or slow-healing skin, hair thinning.',
    sources: ['Beef', 'Pumpkin seeds', 'Beans & chickpeas', 'Nuts', 'Dairy'],
    dailyNeed: '11 mg (boys 14–18), 9 mg (girls 14–18).',
  ),
  NutrientInfo(
    name: 'Calcium',
    emoji: '🦴',
    helps: ['Bones', 'Growth', 'Teeth'],
    whatItDoes:
        'Builds bones and teeth. The teenage years are when you build most of '
        'your peak bone mass.',
    lowSigns: 'Usually silent; over time it leads to weak bones.',
    sources: ['Milk & mala', 'Yoghurt', 'Omena (with bones)', 'Tofu', 'Sardines',
        'Greens'],
    dailyNeed: '1300 mg (ages 9–18), 1000 mg (adults).',
  ),
  NutrientInfo(
    name: 'Vitamin D',
    emoji: '☀️',
    helps: ['Bones', 'Immunity', 'Mood'],
    whatItDoes:
        'Helps the body absorb calcium. It is made in the skin from sunlight.',
    lowSigns: 'Weak bones, muscle aches, frequent illness.',
    sources: ['Sunlight (10–20 min/day)', 'Oily fish', 'Egg yolks', 'Fortified milk'],
    dailyNeed: '15 µg (600 IU) per day.',
  ),
  NutrientInfo(
    name: 'Omega-3 fats',
    emoji: '🐟',
    helps: ['Skin', 'Brain', 'Heart', 'Eyes'],
    whatItDoes:
        'Healthy fats that are part of brain and eye cell membranes and help '
        'calm inflammation, including in the skin.',
    lowSigns: 'Dry skin, poor concentration.',
    sources: ['Sardines & omena', 'Salmon', 'Chia & flax seeds', 'Walnuts'],
    dailyNeed: 'About 2 portions of oily fish a week.',
  ),
  NutrientInfo(
    name: 'Fibre',
    emoji: '🌾',
    helps: ['Digestion', 'Fullness', 'Blood sugar'],
    whatItDoes:
        'Feeds good gut bacteria, keeps you full and slows sugar release into '
        'the blood. Useful for weight control.',
    lowSigns: 'Constipation, feeling hungry soon after meals.',
    sources: ['Beans & githeri', 'Oats', 'Whole-wheat bread', 'Fruit & vegetables',
        'Arrow roots'],
    dailyNeed: '≈25–38 g per day (14 g per 1000 kcal).',
  ),
  NutrientInfo(
    name: 'Water',
    emoji: '💧',
    helps: ['Energy', 'Skin', 'Focus', 'Performance'],
    whatItDoes:
        'Regulates temperature, carries nutrients and keeps skin hydrated. Even '
        '2% dehydration reduces concentration and sports performance.',
    lowSigns: 'Headache, dark urine, tiredness, dry skin.',
    sources: ['Water', 'Fruit like watermelon', 'Soups', 'Milk'],
    dailyNeed: '≈35 ml per kg of body weight, more in hot weather or when training.',
  ),
];
