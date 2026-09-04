class SquadSeller {
  const SquadSeller({
    required this.name,
    required this.contribution,
    required this.skills,
    required this.location,
    required this.reliability,
  });

  final String name;
  final int contribution;
  final String skills;
  final String location;
  final int reliability;
}

class CollaborativeOrder {
  const CollaborativeOrder({
    required this.title,
    required this.totalUnits,
    required this.sellers,
  });

  final String title;
  final int totalUnits;
  final List<SquadSeller> sellers;

  int get allocatedUnits {
    return sellers.fold(
      0,
      (sum, seller) => sum + seller.contribution,
    );
  }
}

const mockFestivalOrder = CollaborativeOrder(
  title: 'Corporate Festival Gift Order',
  totalUnits: 500,
  sellers: [
    SquadSeller(
      name: 'Lakshmi',
      contribution: 150,
      skills: 'Traditional cooking, laddoos',
      location: 'Mylapore, Chennai',
      reliability: 98,
    ),
    SquadSeller(
      name: 'Meena',
      contribution: 100,
      skills: 'Savouries, packaging',
      location: 'Adyar, Chennai',
      reliability: 96,
    ),
    SquadSeller(
      name: 'Revathi',
      contribution: 100,
      skills: 'Gift packing, crafts',
      location: 'T. Nagar, Chennai',
      reliability: 94,
    ),
    SquadSeller(
      name: 'Shanthi',
      contribution: 150,
      skills: 'Traditional cooking, snacks',
      location: 'Velachery, Chennai',
      reliability: 97,
    ),
  ],
);