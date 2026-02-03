import 'package:fluent_ui/fluent_ui.dart';
import '../../data/models.dart';
import '../../logic/yoga_dosha_analyzer.dart';
import '../widgets/strength_meter.dart';

class YogaDoshaScreen extends StatefulWidget {
  final CompleteChartData chartData;

  const YogaDoshaScreen({super.key, required this.chartData});

  @override
  State<YogaDoshaScreen> createState() => _YogaDoshaScreenState();
}

class _YogaDoshaScreenState extends State<YogaDoshaScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final analysis = YogaDoshaAnalyzer.analyze(widget.chartData);

    // Convert String lists to Map objects for UI
    final yogaStrings = analysis['yogas'] as List;
    final doshasStrings = analysis['doshas'] as List;

    final yogas = yogaStrings
        .map(
          (y) => {
            'name': y.toString(),
            'description': _getYogaDescription(y.toString()),
          },
        )
        .toList();

    final doshas = doshasStrings
        .map(
          (d) => {
            'name': d.toString(),
            'description': _getDoshaDescription(d.toString()),
          },
        )
        .toList();

    return NavigationView(
      appBar: const NavigationAppBar(
        title: Text('Yoga & Dosha Analysis'),
        leading: SizedBox.shrink(), // Managed by Navigator usually
      ),
      pane: NavigationPane(
        selected: _currentIndex,
        onChanged: (index) => setState(() => _currentIndex = index),
        displayMode: PaneDisplayMode.top,
        items: [
          PaneItem(
            icon: const Icon(FluentIcons.report_document),
            title: const Text('Summary'),
            body: _buildBody(
              _buildSummaryTab({'yogas': yogas, 'doshas': doshas}),
            ),
          ),
          PaneItem(
            icon: const Icon(FluentIcons.favorite_star),
            title: const Text('Yogas'),
            body: _buildBody(_buildYogasTab(yogas)),
          ),
          PaneItem(
            icon: const Icon(FluentIcons.warning),
            title: const Text('Doshas'),
            body: _buildBody(_buildDoshasTab(doshas)),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(Widget content) {
    return ScaffoldPage(
      content: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: content,
      ),
    );
  }

  Widget _buildSummaryTab(Map<String, dynamic> analysis) {
    final yogas = analysis['yogas'] as List;
    final doshas = analysis['doshas'] as List;

    // Calculate overall score
    final yogaCount = yogas.length;
    final doshaCount = doshas.length;
    final overallScore = ((yogaCount - doshaCount) / 10 * 50 + 50)
        .clamp(0, 100)
        .toDouble();

    return ListView(
      padding: const EdgeInsets.only(bottom: 20),
      children: [
        // Overall chart quality
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Text(
                  'Overall Chart Quality',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                CircularScoreIndicator(
                  score: overallScore,
                  label: _getQualityLabel(overallScore),
                  size: 120,
                ),
                const SizedBox(height: 16),
                Text(
                  _getQualityDescription(overallScore),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Yoga count
        Card(
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
              child: const Icon(FluentIcons.completed, color: Colors.white),
            ),
            title: const Text('Auspicious Yogas'),
            subtitle: Text('$yogaCount yoga(s) detected'),
            trailing: Text(
              '$yogaCount',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ),
        ),

        const SizedBox(height: 8),

        // Dosha count
        Card(
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(FluentIcons.warning, color: Colors.white),
            ),
            title: const Text('Doshas/Challenges'),
            subtitle: Text('$doshaCount dosha(s) detected'),
            trailing: Text(
              '$doshaCount',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Quick highlights
        if (yogas.isNotEmpty) ...[
          const Text(
            'Notable Yogas',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...yogas.take(3).map((yoga) => _buildQuickYogaCard(yoga)),
        ],

        if (doshas.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text(
            'Important Doshas',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...doshas.map((dosha) => _buildQuickDoshaCard(dosha)),
        ],
      ],
    );
  }

  Widget _buildYogasTab(List yogas) {
    if (yogas.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(FluentIcons.info, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'No major yogas detected',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    // Group yogas by type
    final groupedYogas = <String, List>{};
    for (var yoga in yogas) {
      final type = _getYogaType(yoga['name']);
      groupedYogas.putIfAbsent(type, () => []);
      groupedYogas[type]!.add(yoga);
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 20),
      children: [
        Card(
          backgroundColor: Colors.green.withOpacity(0.1),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(FluentIcons.info, color: Colors.green),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Yogas are auspicious planetary combinations that bring positive results in various areas of life.',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        ...groupedYogas.entries.map((entry) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  entry.key,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ...entry.value.map((yoga) => _buildYogaCard(yoga)),
              const SizedBox(height: 8),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildDoshasTab(List doshas) {
    if (doshas.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(FluentIcons.completed, size: 64, color: Colors.green),
              const SizedBox(height: 16),
              Text(
                'No major doshas detected!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'This is a favorable chart without significant afflictions.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 20),
      children: [
        Card(
          backgroundColor: Colors.orange.withValues(alpha: 0.1),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(FluentIcons.warning, color: Colors.orange),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Doshas are challenging combinations. Understanding them helps in planning remedies and precautions.',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        ...doshas.map((dosha) => _buildDoshaCard(dosha)),
      ],
    );
  }

  Widget _buildQuickYogaCard(Map<String, dynamic> yoga) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Card(
        child: ListTile(
          leading: Icon(FluentIcons.favorite_star, color: Colors.yellow),
          title: Text(yoga['name']),
          subtitle: Text(
            yoga['description'],
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  Widget _buildQuickDoshaCard(Map<String, dynamic> dosha) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Card(
        child: ListTile(
          leading: Icon(FluentIcons.warning, color: Colors.orange),
          title: Text(dosha['name']),
          subtitle: Text(
            dosha['description'],
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  Widget _buildYogaCard(Map<String, dynamic> yoga) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Expander(
        header: Row(
          children: [
            Icon(FluentIcons.favorite_star, color: Colors.yellow, size: 24),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  yoga['name'],
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  _getYogaType(yoga['name']),
                  style: TextStyle(fontSize: 12, color: Colors.green),
                ),
              ],
            ),
          ],
        ),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Description:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 6),
            Text(yoga['description']),
            const SizedBox(height: 12),
            const Text(
              'Effects:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 6),
            Text(_getYogaEffects(yoga['name'])),
          ],
        ),
      ),
    );
  }

  Widget _buildDoshaCard(Map<String, dynamic> dosha) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Expander(
        header: Row(
          children: [
            Icon(FluentIcons.warning, color: Colors.orange, size: 24),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dosha['name'],
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Remedial measures recommended',
                  style: TextStyle(fontSize: 12, color: Colors.orange),
                ),
              ],
            ),
          ],
        ),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Description:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 6),
            Text(dosha['description']),
            const SizedBox(height: 12),
            const Text(
              'Remedies:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 6),
            Text(_getDoshaRemedies(dosha['name'])),
          ],
        ),
      ),
    );
  }

  String _getQualityLabel(double score) {
    if (score >= 80) return 'Excellent';
    if (score >= 65) return 'Very Good';
    if (score >= 50) return 'Good';
    if (score >= 35) return 'Average';
    return 'Challenging';
  }

  String _getQualityDescription(double score) {
    if (score >= 80) {
      return 'This is an excellent chart with strong positive combinations and minimal afflictions.';
    } else if (score >= 65) {
      return 'This is a very good chart with several beneficial yogas that support success.';
    } else if (score >= 50) {
      return 'This is a good chart with balanced energies and opportunities for growth.';
    } else if (score >= 35) {
      return 'This chart has average potential with both opportunities and challenges to navigate.';
    }
    return 'This chart has some challenges that require conscious effort and remedial measures.';
  }

  String _getYogaType(String name) {
    if (name.contains('Gaja') || name.contains('Raj')) {
      return 'Raj Yogas (Power & Status)';
    }
    if (name.contains('Dhana') || name.contains('Lakshmi')) {
      return 'Dhana Yogas (Wealth)';
    }
    if (name.contains('Saraswati')) return 'Learning & Wisdom';
    if (name.contains('Neecha Bhanga')) return 'Cancellation Yogas';
    if (name.contains('Parivartana')) return 'Exchange Yogas';
    if (name.contains('Ruchaka') ||
        name.contains('Bhadra') ||
        name.contains('Hamsa') ||
        name.contains('Malavya') ||
        name.contains('Sasa')) {
      return 'Panchamahapurusha Yogas (Five Great Persons)';
    }
    return 'Special Yogas';
  }

  String _getYogaEffects(String name) {
    // Simplified - in reality this would be more comprehensive
    if (name.contains('Gaja')) {
      return 'Brings wisdom, prosperity, and good reputation. Person may achieve high positions and respect in society.';
    } else if (name.contains('Dhana')) {
      return 'Indicates wealth accumulation and financial prosperity. Good for business and investments.';
    } else if (name.contains('Raj')) {
      return 'Grants authority, leadership qualities, and success in administrative positions.';
    } else if (name.contains('Ruchaka')) {
      return 'Mars-based yoga granting courage, physical strength, military skills, and leadership in combative fields. Person becomes bold, energetic, and achieves success through valor.';
    } else if (name.contains('Bhadra')) {
      return 'Mercury-based yoga bestowing intelligence, eloquence, business acumen, and scholarly achievements. Person excels in communication, mathematics, and analytical skills.';
    } else if (name.contains('Hamsa')) {
      return 'Jupiter-based yoga conferring wisdom, spirituality, righteousness, and respect. Person becomes learned, ethical, and may achieve spiritual or religious prominence.';
    } else if (name.contains('Malavya')) {
      return 'Venus-based yoga bringing beauty, luxury, artistic talents, and charisma. Person enjoys material comforts, aesthetic pleasures, and success in creative fields.';
    } else if (name.contains('Sasa')) {
      return 'Saturn-based yoga granting discipline, perseverance, authority over masses, and success through hard work. Person achieves positions of responsibility and power over time.';
    }
    return 'Brings positive results in areas indicated by the planets and houses involved.';
  }

  String _getDoshaRemedies(String name) {
    if (name.contains('Kaal Sarp')) {
      return 'Chant Maha Mrityunjaya mantra, worship Lord Shiva, donate on Saturdays, perform Rahu-Ketu puja.';
    } else if (name.contains('Mangal')) {
      return 'Worship Lord Hanuman, recite Mars mantras, donate red items on Tuesdays, fast on Tuesdays.';
    } else if (name.contains('Pitra')) {
      return 'Perform Shraddha rituals, donate to elders, worship ancestors, feed Brahmins on Amavasya.';
    }
    return 'Consult with an experienced astrologer for personalized remedial measures.';
  }

  String _getYogaDescription(String name) {
    if (name.contains('Gajakesari')) {
      return 'Jupiter in a Kendra (angle) from the Moon creates this auspicious yoga for wisdom and prosperity.';
    } else if (name.contains('Budhaditya')) {
      return 'Sun and Mercury conjunction bestows intelligence, communication skills, and learning ability.';
    } else if (name.contains('Chandra Mangala')) {
      return 'Moon-Mars combination indicates courage, wealth accumulation, and strong determination.';
    } else if (name.contains('Raj Yoga')) {
      return 'Combination of Kendra and Trikona lords brings power, status, and leadership qualities.';
    } else if (name.contains('Dhana')) {
      return 'Wealth-producing combination indicating financial prosperity and material success.';
    } else if (name.contains('Vipreet')) {
      return 'Reversed raja yoga from lords of 6th, 8th, or 12th houses bringing unexpected success.';
    } else if (name.contains('Neecha Bhanga')) {
      return 'Cancellation of planetary debilitation turning weakness into strength unexpectedly.';
    } else if (name.contains('Parivartana')) {
      return 'Mutual exchange of houses between planets creating powerful synergy.';
    } else if (name.contains('Adhi')) {
      return 'Benefic planets surrounding the Moon bringing mental peace and prosperity.';
    } else if (name.contains('Lakshmi')) {
      return 'Venus with 9th lord combination indicating wealth, luxury, and fortune.';
    } else if (name.contains('Saraswati')) {
      return 'Combination of Jupiter, Venus, and Mercury promoting arts, learning, and wisdom.';
    } else if (name.contains('Amala')) {
      return 'Benefic planet in 10th house from Lagna or Moon bringing pure reputation.';
    } else if (name.contains('Parvata')) {
      return 'Benefics in angles without malefic aspects indicating elevated status.';
    } else if (name.contains('Kahala')) {
      return '4th and 9th lords in mutual kendras indicating stubborn determination and valor.';
    } else if (name.contains('Chamara')) {
      return 'Exalted Lagna lord in a kendra bringing royal support and attendants.';
    } else if (name.contains('Sankha')) {
      return '5th and 6th lords in mutual kendras bringing wealth, fame, and prosperity.';
    } else if (name.contains('Ruchaka')) {
      return 'Mars in own sign (Aries/Scorpio) or exaltation (Capricorn) in a Kendra (1st, 4th, 7th, or 10th house) from Lagna. One of the five Panchamahapurusha Yogas.';
    } else if (name.contains('Bhadra')) {
      return 'Mercury in own sign (Gemini/Virgo) or exaltation (Virgo) in a Kendra from Lagna. One of the five Panchamahapurusha Yogas.';
    } else if (name.contains('Hamsa')) {
      return 'Jupiter in own sign (Sagittarius/Pisces) or exaltation (Cancer) in a Kendra from Lagna. One of the five Panchamahapurusha Yogas.';
    } else if (name.contains('Malavya')) {
      return 'Venus in own sign (Taurus/Libra) or exaltation (Pisces) in a Kendra from Lagna. One of the five Panchamahapurusha Yogas.';
    } else if (name.contains('Sasa')) {
      return 'Saturn in own sign (Capricorn/Aquarius) or exaltation (Libra) in a Kendra from Lagna. One of the five Panchamahapurusha Yogas.';
    }

    // Nabhasa
    if (name.contains('Rajju')) {
      return 'All planets situated in movable signs (Aries, Cancer, Libra, Capricorn).';
    }
    if (name.contains('Musala')) {
      return 'All planets situated in fixed signs (Taurus, Leo, Scorpio, Aquarius).';
    }
    if (name.contains('Nala')) {
      return 'All planets situated in dual signs (Gemini, Virgo, Sagittarius, Pisces).';
    }
    if (name.contains('Mala')) {
      return 'All planets distributed in three consecutive separate Kendras.';
    }
    if (name.contains('Sarpa')) {
      return 'All planets distributed in three consecutive separate Panaparas.';
    }
    if (name.contains('Gadha')) {
      return 'All planets distributed in two consecutive separate Kendras.';
    }
    if (name.contains('Vallaki')) {
      return 'Planets distributed in 7 signs (Sankhya) or all Kendras except one (Akriti).';
    }
    if (name.contains('Damini')) {
      return 'All planets distributed in 6 signs (Sankhya) or Kendras + 6th/8th (Akriti).';
    }
    if (name.contains('Pasa')) {
      return 'All planets distributed in 5 signs (Sankhya) or all Panaparas (Akriti).';
    }
    if (name.contains('Kedara')) {
      return 'All planets distributed in 4 signs (Sankhya) or 2nd, 4th, 7th, 8th (Akriti).';
    }
    if (name.contains('Sula')) {
      return 'All planets distributed in 3 signs (Sankhya) or specific Kendra/Panapara pattern (Akriti).';
    }
    if (name.contains('Yuga')) {
      return 'All planets distributed in 2 signs (Sankhya) or Kendras except one (Akriti).';
    }
    if (name.contains('Gola')) {
      return 'All planets concentrated in 1 sign (Sankhya) or 1 Kendra (Akriti).';
    }
    if (name.contains('Vajra')) {
      return 'Benefics in 1st & 7th, Malefics in 4th & 10th houses.';
    }
    if (name.contains('Yava')) {
      return 'Malefics in 1st & 7th, Benefics in 4th & 10th houses.';
    }
    if (name.contains('Kamala')) {
      return 'All planets occupying all four Kendra houses.';
    }
    if (name.contains('Vapi')) {
      return 'All planets occupying Panapara houses (2, 5, 8, 11).';
    }
    if (name.contains('Yupa')) {
      return 'All planets occupying Apoklima houses (3, 6, 9, 12).';
    }
    if (name.contains('Ishu')) {
      return 'All planets occupying houses 3, 6, 9, 12.';
    }
    if (name.contains('Sakti')) return 'All planets occupying houses 7, 8, 9.';
    if (name.contains('Danda')) return 'All planets occupying houses 4, 5, 6.';
    if (name.contains('Naukha')) return 'All planets occupying houses 1, 2, 3.';
    if (name.contains('Chatra')) {
      return 'All planets occupying houses 10, 11, 12.';
    }
    if (name.contains('Chapa')) {
      return 'All planets occupying 1st, 4th, 7th, 10th house.';
    }
    if (name.contains('Ardha')) {
      return 'All planets occupying 7 consecutive houses.';
    }

    // Lunar/Solar
    if (name.contains('Sunapha')) {
      return 'Planet (except Sun) in 2nd house from Moon.';
    }
    if (name.contains('Anapha')) {
      return 'Planet (except Sun) in 12th house from Moon.';
    }
    if (name.contains('Durudhara')) {
      return 'Planets in both 2nd and 12th houses from Moon.';
    }
    if (name.contains('Vesi')) {
      return 'Planet (except Moon) in 2nd house from Sun.';
    }
    if (name.contains('Vasi')) {
      return 'Planet (except Moon) in 12th house from Sun.';
    }
    if (name.contains('Ubhayachari')) {
      return 'Planets in both 2nd and 12th houses from Sun.';
    }

    // Wealth/Power/Special
    if (name.contains('Vasumathi')) {
      return 'Benefic planets occupying Upachaya houses (3, 6, 10, 11) from Moon or Lagna.';
    }
    if (name.contains('Pushkala')) {
      return 'Lagna Lord exalted and Moon in own/friendly sign.';
    }
    if (name.contains('Indra')) {
      return 'Exchange of lords of 5th and 11th houses, combined with strong Moon.';
    }
    if (name.contains('Ravi')) return 'Sun in 10th house conjunct with Venus.';
    if (name.contains('Nipuna')) {
      return 'Sun and Mercury conjunction within 10 degrees.';
    }
    if (name.contains('Guru Mangala')) {
      return 'Conjunction of Jupiter and Mars.';
    }
    if (name.contains('Shubha Kartari')) {
      return 'Lagna hemmed between benefic planets in 2nd and 12th.';
    }
    if (name.contains('Papa Kartari')) {
      return 'Lagna hemmed between malefic planets in 2nd and 12th.';
    }

    return 'An auspicious planetary combination bringing positive results in life.';
  }

  String _getDoshaDescription(String name) {
    if (name.contains('Kaal Sarp')) {
      return 'All planets hemmed between Rahu and Ketu creating obstacles and delays but also spiritual growth.';
    } else if (name.contains('Manglik') || name.contains('Kuja')) {
      return 'Mars in sensitive houses (1st, 2nd, 4th, 7th, 8th, or 12th) affecting marriage and relationships.';
    } else if (name.contains('Pitra')) {
      return 'Affliction of Sun or Moon by Rahu, Ketu, or Saturn indicating ancestral karma.';
    } else if (name.contains('Kemadruma')) {
      return 'Moon without support from neighboring houses creating loneliness or mental unrest.';
    }

    // Planetary Conjunctions
    if (name.contains('Guru Chandal')) {
      return 'Jupiter combined with Rahu or Ketu. Can corrupt wisdom and ethics.';
    }
    if (name.contains('Angarak')) {
      return 'Mars combined with Rahu or Ketu. Indicates aggression and accident risks.';
    }
    if (name.contains('Shrapit')) {
      return 'Saturn combined with Rahu. Indicates karmic curse and chronic delays.';
    }
    if (name.contains('Vish')) {
      return 'Saturn combined with Moon. Can cause mental stress and depression.';
    }
    if (name.contains('Grahan') && name.contains('Surya')) {
      return 'Sun combined with Nodes. Afflicts soul, father, and vitality.';
    }
    if (name.contains('Grahan') && name.contains('Chandra')) {
      return 'Moon combined with Nodes. Afflicts mind, mother, and emotions.';
    }
    if (name.contains('Sangharsha')) {
      return 'Sun and Saturn in conflict. Indicates authority struggles.';
    }
    if (name.contains('Yama')) {
      return 'Mars and Saturn conjunction. Technical skill but high conflict/injury risk.';
    }

    // House & Placement
    if (name.contains('Sakat')) {
      return 'Moon placed in 6th, 8th, or 12th from Jupiter. Causes fluctuating fortune.';
    }
    if (name.contains('Kendradhipati')) {
      return 'Benefic planets owning Kendra houses losing their beneficence.';
    }
    if (name.contains('Karako')) {
      return 'Significator placed in the house it signifies. Can harm the signification.';
    }
    if (name.contains('Bandhana')) {
      return 'Equal number of planets in axis houses. Indicates restriction or confinement.';
    }
    if (name.contains('Badhak')) {
      return 'Influence of the obstruction creator (Badhak) on Lagna.';
    }
    if (name.contains('Maraka')) {
      return 'Planets in or owning Maraka houses (2nd and 7th). Health critical periods.';
    }
    if (name.contains('Daridra')) {
      return 'Lord of 11th in 6th, 8th, or 12th house. Indicates loss of wealth.';
    }

    // State & Strength
    if (name.contains('Gandanta')) {
      return 'Moon or Ascendant in junction of Water and Fire signs. Emotional or physical struggle.';
    }
    if (name.contains('Moudhya')) {
      return 'Planet too close to Sun (Combust). Losing its power and vitality.';
    }
    if (name.contains('Neecha')) {
      return 'Planet in its debilitation sign without cancellation. Weakness in related areas.';
    }

    // Karmic / Lifestyle
    if (name.contains('Balarishta')) {
      return 'Combinations indicating danger to health in childhood.';
    }
    if (name.contains('Kalatra')) {
      return 'General affliction to 7th house/lord. Indicates spouse health issues.';
    }
    if (name.contains('Papakartari')) {
      return 'Lagna or house hemmed between two malefic planets. Constricts growth and significance.';
    }

    return 'A challenging planetary combination requiring awareness and remedial measures.';
  }
}
