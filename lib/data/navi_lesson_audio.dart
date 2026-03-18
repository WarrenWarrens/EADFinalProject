import '../models/lesson_model.dart';

/// Lesson 2 — Na'vi Audio Mimicry
/// 15 items ordered from most common/simple (tier 1) to expressive (tier 3).
/// IPA sourced from Reykunyu (reykunyu.lu). TTS hints use X-SAMPA approximations
/// suitable for passing to ElevenLabs pronunciation dictionary or Google SSML phoneme tags.
const naviAudioLesson = Lesson(
  id: 'navi_audio_01',
  language: 'navi',
  title: 'Greetings & Basics',
  description: 'Core Na\'vi words and phrases every speaker needs first.',
  vocab: [
    // ── Tier 1 — Beginner (items 1–5) ────────────────────────────────────
    VocabItem(
      id: 'nv_01',
      navi: 'Kaltxì',
      ipa: '/kal.tʼɪ/',
      english: 'Hello',
      ttsHint: 'kahl-tʼee',
      tier: 1,
    ),
    VocabItem(
      id: 'nv_02',
      navi: 'Irayo',
      ipa: '/i.ɾa.jo/',
      english: 'Thank you',
      ttsHint: 'ee-rah-yo',
      tier: 1,
    ),
    VocabItem(
      id: 'nv_03',
      navi: 'Srane',
      ipa: '/sɾa.nɛ/',
      english: 'Yes',
      ttsHint: 'srah-neh',
      tier: 1,
    ),
    VocabItem(
      id: 'nv_04',
      navi: 'Kehe',
      ipa: '/kɛ.hɛ/',
      english: 'No',
      ttsHint: 'keh-heh',
      tier: 1,
    ),
    VocabItem(
      id: 'nv_05',
      navi: 'Oe',
      ipa: '/o.ɛ/',
      english: 'I / me',
      ttsHint: 'oh-eh',
      tier: 1,
    ),

    // ── Tier 2 — Intermediate (items 6–10) ───────────────────────────────
    VocabItem(
      id: 'nv_06',
      navi: 'Nga',
      ipa: '/ŋa/',
      english: 'You',
      ttsHint: 'ngah',
      tier: 2,
    ),
    VocabItem(
      id: 'nv_07',
      navi: 'Eywa ngahu',
      ipa: '/ɛj.wa ŋa.hu/',
      english: 'Eywa be with you',
      ttsHint: 'ay-wah ngah-hoo',
      tier: 2,
    ),
    VocabItem(
      id: 'nv_08',
      navi: 'Kìyevame',
      ipa: '/kɪ.jɛ.va.mɛ/',
      english: 'See you later (goodbye)',
      ttsHint: 'kee-yeh-vah-meh',
      tier: 2,
    ),
    VocabItem(
      id: 'nv_09',
      navi: 'Oel ngati kameie',
      ipa: '/o.ɛl ŋa.ti ka.mɛ.i.ɛ/',
      english: 'I see you (deep greeting)',
      ttsHint: 'oh-el ngah-tee kah-meh-ee-eh',
      tier: 2,
    ),
    VocabItem(
      id: 'nv_10',
      navi: 'Ngaru lu fpom srak?',
      ipa: '/ŋa.ɾu lu f̩.pom sɾak/',
      english: 'How are you?',
      ttsHint: 'ngah-roo loo fpom srahk',
      tier: 2,
    ),

    // ── Tier 3 — Native (items 11–15) ────────────────────────────────────
    VocabItem(
      id: 'nv_11',
      navi: 'Oe lu nitram',
      ipa: '/o.ɛ lu nit.ɾam/',
      english: 'I am happy',
      ttsHint: 'oh-eh loo nit-rahm',
      tier: 3,
    ),
    VocabItem(
      id: 'nv_12',
      navi: 'Fìtseng',
      ipa: '/fɪ.tsɛŋ/',
      english: 'Here / in this place',
      ttsHint: 'fee-tseng',
      tier: 3,
    ),
    VocabItem(
      id: 'nv_13',
      navi: 'Tìyawn',
      ipa: '/tɪ.jawn/',
      english: 'Love',
      ttsHint: 'tee-yown',
      tier: 3,
    ),
    VocabItem(
      id: 'nv_14',
      navi: 'Hayalovay',
      ipa: '/ha.ja.lo.vaj/',
      english: 'Until next time',
      ttsHint: 'hah-yah-lo-vye',
      tier: 3,
    ),
    VocabItem(
      id: 'nv_15',
      navi: 'Tsun oe ngahu pivängkxo a fì\'u oeru prrte\' lu',
      ipa: '/tsun o.ɛ ŋa.hu pi.væŋ.kʼo a fɪ.ʔu o.ɛ.ɾu pɾː.tɛ lu/',
      english: 'It is a pleasure to speak with you',
      ttsHint: "tsoon oh-eh ngah-hoo pee-veng-kxo ah fee-oo oh-eh-roo prr-teh loo",
      tier: 3,
    ),
  ],
);