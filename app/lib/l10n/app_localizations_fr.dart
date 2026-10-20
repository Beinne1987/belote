// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Belote';

  @override
  String get teamUs => 'Nous';

  @override
  String get teamThem => 'Eux';

  @override
  String get bidNone => 'Pas de contrat';

  @override
  String get bidAkwins => 'Coinche';

  @override
  String get bidPass => 'Passe';

  @override
  String get bidYours => 'Votre contrat';

  @override
  String get turnYours => 'À vous de jouer';

  @override
  String get bidSans => 'SA';

  @override
  String get bidTout => 'TA';

  @override
  String get suitTrefle => 'Trèfle';

  @override
  String get suitCarreau => 'Carreau';

  @override
  String get suitCoeur => 'Cœur';

  @override
  String get suitPique => 'Pique';

  @override
  String get rankNameA => 'As';

  @override
  String get rankName10 => 'Dix';

  @override
  String get rankNameK => 'Roi';

  @override
  String get rankNameQ => 'Dame';

  @override
  String get rankNameJ => 'Valet';

  @override
  String get rankName9 => 'Neuf';

  @override
  String get rankName8 => 'Huit';

  @override
  String get rankName7 => 'Sept';

  @override
  String cardName(String rank, String suit) {
    return '$rank de $suit';
  }

  @override
  String foujaCardHint(String card) {
    return '$card — irrégulière';
  }

  @override
  String bidWithAkwins(String bid) {
    return '$bid · Coinche';
  }

  @override
  String get phaseDealing => 'Distribution';

  @override
  String get phaseBidding => 'Contrat';

  @override
  String get followSuitRequired => 'Vous devez fournir';

  @override
  String get rankBeginner => 'Débutant';

  @override
  String get rankPro => 'Confirmé';

  @override
  String get rankExpert => 'Expert';

  @override
  String get rankLegend => 'Légende';

  @override
  String get seatYou => 'Vous';

  @override
  String get seatOpponent => 'Adversaire';

  @override
  String get seatPartner => 'Partenaire';

  @override
  String get roundOver => 'Manche terminée';

  @override
  String get roundNew => 'Nouvelle manche';

  @override
  String get matchNew => 'Nouvelle partie';

  @override
  String get backToMenu => 'Menu';

  @override
  String get rating => 'Classement';

  @override
  String get roundValue => 'Valeur de la manche';

  @override
  String get matchWonUs => 'Vous avez gagné la partie !';

  @override
  String get matchWonThem => 'L\'adversaire a gagné la partie';

  @override
  String get matchTiebreak => 'Égalité — manche décisive';

  @override
  String get openRuleTie =>
      'Règle ouverte : égalité sur la Coinche (rare — sans arbitrage)';

  @override
  String get fouja => 'Fouja';

  @override
  String get foujaWho => 'Qui a fait la fouja ?';

  @override
  String get opponentRight => 'Adversaire à votre droite';

  @override
  String get opponentLeft => 'Adversaire à votre gauche';

  @override
  String get cancel => 'Annuler';

  @override
  String get foujaCancel => 'Annuler la fouja';

  @override
  String foujaClaimedBy(String name) {
    return '$name réclame la fouja…';
  }

  @override
  String get foujaWonUs => 'Fouja — les points du contrat sont à vous';

  @override
  String get foujaWonThem =>
      'Fouja — les points du contrat vont à l\'adversaire';

  @override
  String get reasonChute => 'Contrat chuté';

  @override
  String get reasonAkwins => 'Coinche';

  @override
  String get reasonWhite => 'Manche blanche !';

  @override
  String get reasonMade => 'Contrat réussi';

  @override
  String get settingsLanguage => 'Langue';

  @override
  String get settingsLanguageArabic => 'Arabe';

  @override
  String get settingsLanguageFrench => 'Français';

  @override
  String get exitGame => 'Quitter la partie';

  @override
  String get settingsTitle => 'Paramètres';

  @override
  String get settingsName => 'Nom';

  @override
  String get settingsTheme => 'Thème';

  @override
  String get settingsSound => 'Son';

  @override
  String get howToPlay => 'Comment jouer';

  @override
  String get supportSection => 'Assistance';

  @override
  String get supportEmail => 'E-mail';

  @override
  String get openFailed => 'Impossible d\'ouvrir sur cet appareil.';

  @override
  String get save => 'Enregistrer';

  @override
  String appVersion(String version) {
    return 'Version $version';
  }

  @override
  String get serverUnreachable => 'Connexion au serveur impossible';

  @override
  String get friendsFetchFailed => 'Impossible de charger les amis';

  @override
  String get noFriendsYet =>
      'Aucun ami — ajoutez-les depuis l\'écran Amis avec leur code.';

  @override
  String get invitePartnerPays =>
      'Invitez un partenaire — il paie sa mise en acceptant';

  @override
  String get unknownInitial => '?';

  @override
  String get tournaments => 'Tournois';

  @override
  String get signInForTournaments =>
      'Connectez-vous pour participer aux tournois';

  @override
  String get retry => 'Réessayer';

  @override
  String get createYourEvent => 'Créez votre tournoi';

  @override
  String get createEventSubtitle =>
      'À votre nom, avec la mise de votre choix — création 50💎';

  @override
  String get create => 'Créer';

  @override
  String get newEvent => 'Nouveau tournoi';

  @override
  String get eventName => 'Nom du tournoi';

  @override
  String get entryFeeField => 'Mise d\'entrée (10–500 💎)';

  @override
  String get sizeLabel => 'Taille :';

  @override
  String teamsCount(int count) {
    return '$count équipes';
  }

  @override
  String eventSchedule(String date, String time) {
    return 'Date : $date · $time';
  }

  @override
  String get createEventTerms =>
      'La création (50💎) n\'est pas remboursée. Les mises des participants forment la cagnotte des gagnants (la maison prélève 20 %) — l\'organisateur n\'en reçoit rien ; le tournoi porte votre nom.';

  @override
  String get createEventConfirm => 'Créer le tournoi — 50💎';

  @override
  String hoursMinutes(int h, int m) {
    return '$h h $m min';
  }

  @override
  String get eventLive => 'En cours';

  @override
  String get eventPlayerMade => 'Tournoi de joueur';

  @override
  String get eventOfficial => 'Événement';

  @override
  String eventOrganizer(String name) {
    return 'Organisé par : $name';
  }

  @override
  String eventStats(int fee, int players, int size, int pool) {
    return 'Entrée : $fee💎  ·  Inscrits : $players/$size  ·  Cagnotte : $pool💎';
  }

  @override
  String startsIn(String time) {
    return 'Débute dans $time';
  }

  @override
  String partnerInviteEvent(String name) {
    return '$name vous invite comme partenaire pour cet événement 🤝';
  }

  @override
  String get accept => 'Accepter';

  @override
  String get decline => 'Refuser';

  @override
  String get withdrawRefund => 'Se retirer et être remboursé';

  @override
  String get invitePartner => 'Inviter un partenaire';

  @override
  String registerForFee(int fee) {
    return 'S\'inscrire — $fee💎';
  }

  @override
  String yourPartner(String name) {
    return 'Votre partenaire : $name 🤝';
  }

  @override
  String get cancelMyEvent => 'Annuler mon tournoi';

  @override
  String cancelEventTitle(String title) {
    return 'Annuler « $title » ?';
  }

  @override
  String cancelEventBody(int players) {
    return 'Les mises des $players inscrits sont intégralement remboursées. Les 50💎 de création ne le sont pas.';
  }

  @override
  String get back => 'Retour';

  @override
  String get cancelEventConfirm => 'Annuler le tournoi';

  @override
  String get lastTournamentChampions => 'Champions du dernier tournoi';

  @override
  String partnerInvite(String name) {
    return '$name vous invite comme partenaire 🤝';
  }

  @override
  String get partnerInviteRegistered =>
      'En acceptant, vous serez partenaires à la même table.';

  @override
  String partnerInviteWillPay(int fee) {
    return 'En acceptant, vous vous inscrivez, payez votre mise ($fee💎) et devenez partenaires.';
  }

  @override
  String get todaysTournament => 'Tournoi du jour';

  @override
  String knockoutSize(int size) {
    return 'Élimination directe à $size';
  }

  @override
  String tournamentStats(int fee, int pool) {
    return 'Entrée : $fee💎 par personne  ·  Cagnotte à ce jour : $pool💎';
  }

  @override
  String get tournamentPayoutNote =>
      'La paire gagnante se partage la cagnotte — l\'IA complète les places au départ.';

  @override
  String startsWithin(String time) {
    return 'Débute dans $time';
  }

  @override
  String registeredCount(int players, int size) {
    return 'Inscrits $players/$size';
  }

  @override
  String withPartner(String name) {
    return 'avec $name';
  }

  @override
  String get enterYourTable => 'Rejoindre votre table';

  @override
  String get roundFinal => 'Finale';

  @override
  String get roundSemi => 'Demi-finale';

  @override
  String get roundQuarter => 'Quart de finale';

  @override
  String roundOfN(int n) {
    return 'Seizièmes ($n)';
  }

  @override
  String get roundGeneric => 'Tour';

  @override
  String roundProgress(int done, int total) {
    return '$done matchs sur $total terminés';
  }

  @override
  String get yourMatchShown => ' — votre match est affiché';

  @override
  String get nextRoundPending =>
      'Le tour suivant se forme dès que ses matchs qualificatifs sont joués…';

  @override
  String get matchLive => 'En cours';

  @override
  String get versus => 'contre';

  @override
  String get botPlayer => 'IA';

  @override
  String get playerFallback => 'Joueur';

  @override
  String reportPlayer(String name) {
    return 'Signaler $name';
  }

  @override
  String blockPlayer(String name) {
    return 'Bloquer $name';
  }

  @override
  String get blockPlayerNote =>
      'Vous ne verrez plus ses messages, il ne peut ni vous écrire ni vous inviter.';

  @override
  String get reportSent => 'Signalement envoyé — il sera examiné.';

  @override
  String playerBlocked(String name) {
    return '$name est bloqué — vous ne verrez plus ses messages.';
  }

  @override
  String get blockFailed => 'Blocage impossible — vérifiez votre connexion.';

  @override
  String get errInviteOffline =>
      'Votre ami est hors ligne et ne reçoit pas les notifications — il ne verra votre invitation qu\'en ouvrant le jeu.';

  @override
  String get errInviteNotFriend =>
      'Ajoutez-le d\'abord comme ami pour l\'inviter.';

  @override
  String get errInviteSeatTaken =>
      'La place est prise — choisissez-en une autre.';

  @override
  String get errInviteStarted =>
      'La partie a commencé — plus d\'invitation possible.';

  @override
  String get errInviteNotPrivate =>
      'Les invitations sont réservées aux tables privées — créez-en une puis invitez-le.';

  @override
  String get errGiftInsufficient =>
      'Vos diamants ne suffisent pas pour ce cadeau.';

  @override
  String get errGiftNotOnTable => 'Il n\'est plus à la table.';

  @override
  String get errGiftSelf => 'Vous ne pouvez pas vous offrir un cadeau.';

  @override
  String get errGiftUnknown => 'Ce cadeau n\'est plus disponible.';

  @override
  String get errVipGiftEmpty =>
      'Cadeaux VIP épuisés aujourd\'hui — trois reviennent demain.';

  @override
  String get errVipGiftNotVip => 'Ces cadeaux sont réservés aux membres VIP.';

  @override
  String get inviteRewardMsg =>
      'Votre ami vous a rejoint — une partie de plus aujourd\'hui ! 🎉';

  @override
  String get errGeneric => 'Action impossible — réessayez.';

  @override
  String spectatingCount(int count) {
    return 'Spectateur · $count';
  }

  @override
  String get enteringStands => 'Entrée dans les tribunes…';

  @override
  String get reconnecting => 'Reconnexion…';

  @override
  String get playOnline => 'Jouer en ligne';

  @override
  String get logout => 'Déconnexion';

  @override
  String get quickMatch => 'Partie rapide';

  @override
  String get quickMatchSub =>
      'Prenez la première table libre avec d\'autres joueurs';

  @override
  String get createPrivateTable => 'Créer une table privée';

  @override
  String get createPrivateTableSub =>
      'Invitez vos amis avec le code de la table';

  @override
  String get tableCode => 'Code de la table';

  @override
  String get joinByCode => 'Rejoindre avec un code';

  @override
  String get seatRolePartner => 'comme partenaire';

  @override
  String get seatRoleOpponent => 'comme adversaire';

  @override
  String invitedPlayer(String name) {
    return '$name a été invité';
  }

  @override
  String get privateTable => 'Table privée';

  @override
  String get quickMatchTitle => 'Partie rapide';

  @override
  String tableCodeIs(String code) {
    return 'Code : $code';
  }

  @override
  String get startMatch => 'Commencer la partie';

  @override
  String get searchingPlayers => 'Recherche de joueurs…';

  @override
  String get searchingPlayersSub =>
      'Nous cherchons des adversaires pour votre table';

  @override
  String get errServerFull => 'Serveurs saturés — réessayez dans un instant.';

  @override
  String get errSpectateUnavailable =>
      'Cette partie est terminée ou n\'est plus visible.';

  @override
  String get errSpectateSeated =>
      'Vous êtes à une table — quittez-la avant de regarder.';

  @override
  String get errPlayLimit =>
      'Vos parties du jour sont épuisées — elles reviennent demain. Le jeu contre l\'IA reste illimité.';

  @override
  String get errJoinFailed => 'Impossible de rejoindre — vérifiez le code.';

  @override
  String get errNoSeat => 'Aucune place libre à cette table.';

  @override
  String get errUnauthorized => 'Session expirée — reconnectez-vous.';

  @override
  String get errConnection => 'Connexion au serveur perdue.';

  @override
  String get errUnexpected => 'Une erreur inattendue s\'est produite.';

  @override
  String get goBack => 'Retour';

  @override
  String invitesYouToTable(String name) {
    return '$name vous invite à sa table';
  }

  @override
  String get later => 'Plus tard';

  @override
  String get join => 'Rejoindre';

  @override
  String get fillingSeatsNote =>
      'Nous cherchons des joueurs pour les places libres… sinon la partie commencera avec l\'IA.';

  @override
  String get playerDefaultName => 'Joueur';

  @override
  String get navHome => 'Accueil';

  @override
  String get navLeaderboard => 'Classement';

  @override
  String get navStore => 'Boutique';

  @override
  String get navFriends => 'Amis';

  @override
  String get navAbout => 'À propos';

  @override
  String get quickPlayOffline => 'Partie rapide';

  @override
  String get quickPlayOfflineSub => 'Contre l\'IA — hors ligne';

  @override
  String get vipActiveSub => 'Abonnement actif — tous vos avantages';

  @override
  String get vipOfferSub => 'Salon privé · cadre · cadeaux · jeu illimité';

  @override
  String get missions => 'Missions';

  @override
  String get missionsSub => 'Quotidiennes et hebdomadaires — XP et diamants';

  @override
  String get tournamentsSub => 'Tournoi du jour · événements dotés';

  @override
  String get liveMatches => 'Matchs en direct';

  @override
  String get liveMatchesSub =>
      'Regardez en direct · encouragez avec des cadeaux';

  @override
  String get comingSoon => 'Bientôt';

  @override
  String get notifications => 'Notifications';

  @override
  String get offline => 'Hors ligne';

  @override
  String get signIn => 'Connexion';

  @override
  String get onlineNeedsSignIn => 'Avec de vrais joueurs — connexion requise';

  @override
  String get onlineWithPlayers => 'Avec de vrais joueurs';

  @override
  String graceUnlimited(String left) {
    return 'Bienvenue ! Jeu illimité — reste : $left';
  }

  @override
  String unlimitedLeft(String left) {
    return 'Jeu illimité — reste : $left';
  }

  @override
  String bonusFromInvites(int bonus) {
    return ' (dont $bonus grâce à vos invitations)';
  }

  @override
  String gamesLeftToday(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Il vous reste $count parties aujourd\'hui',
      one: 'Il vous reste 1 partie aujourd\'hui',
      zero: 'Vos parties du jour sont épuisées — elles reviennent demain',
    );
    return '$_temp0';
  }

  @override
  String get expired => 'Terminé';

  @override
  String daysLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jours',
      one: '1 jour',
    );
    return '$_temp0';
  }

  @override
  String hoursLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count heures',
      one: '1 heure',
      zero: 'moins d\'une heure',
    );
    return '$_temp0';
  }

  @override
  String get myProfile => 'Mon profil';

  @override
  String get signInToSeeProfile =>
      'Connectez-vous pour voir votre profil et vos statistiques';

  @override
  String get signInAction => 'Se connecter';

  @override
  String get statWinRate => 'Taux de victoire';

  @override
  String get statMatches => 'Parties';

  @override
  String get statWins => 'Victoires';

  @override
  String get statLosses => 'Défaites';

  @override
  String get statBestStreak => 'Meilleure série';

  @override
  String get statCurrentStreak => 'Série en cours';

  @override
  String get profilePhoto => 'Photo de profil';

  @override
  String get pickFromGallery => 'Choisir dans la galerie';

  @override
  String get takePhoto => 'Prendre une photo';

  @override
  String get deletePhoto => 'Supprimer la photo';

  @override
  String get photoPermissionError =>
      'Impossible d\'ouvrir la galerie. Vérifiez les autorisations.';

  @override
  String get signOut => 'Se déconnecter';

  @override
  String get deleteAccount => 'Supprimer définitivement le compte';

  @override
  String get signOutNote =>
      'Votre compte reste intact ; reconnectez-vous avec votre numéro et votre mot de passe.';

  @override
  String get backAction => 'Retour';

  @override
  String get signOutConfirm => 'Se déconnecter';

  @override
  String deleteFailed(String reason) {
    return 'Suppression impossible : $reason';
  }

  @override
  String get levelLabel => 'Niveau ';

  @override
  String xpToNext(int xp) {
    return '$xp XP avant le niveau suivant';
  }

  @override
  String get myWallet => 'Mon portefeuille';

  @override
  String get diamonds => 'Diamants';

  @override
  String get myGifts => 'Mes cadeaux';

  @override
  String get noGiftsYet => 'Aucun cadeau — achetez un pack dans la boutique.';

  @override
  String get deleteAccountBody =>
      'Votre nom, votre code, vos diamants, votre classement et vos amis disparaissent. C\'est irréversible.\nVotre numéro reste disponible pour un nouveau compte.';

  @override
  String get typeYourTagToConfirm => 'Saisissez votre code pour confirmer :';

  @override
  String get deleteAccountConfirm => 'Supprimer mon compte';

  @override
  String get addByTag => 'Ajouter avec un code';

  @override
  String get blockedList => 'Bloqués';

  @override
  String get signInToSeeFriends => 'Connectez-vous pour voir vos amis.';

  @override
  String get friendsFetchFailedShort => 'Impossible de charger les amis.';

  @override
  String get incomingRequests => 'Demandes reçues';

  @override
  String get yourFriends => 'Vos amis';

  @override
  String get awaitingReply => 'En attente de réponse';

  @override
  String get online => 'En ligne';

  @override
  String get chat => 'Discussion';

  @override
  String get acceptShort => 'Accepter';

  @override
  String get nowFriends => 'Vous êtes désormais amis';

  @override
  String get declineShort => 'Refuser';

  @override
  String get removeFriendAction => 'Retirer des amis';

  @override
  String get cancelRequest => 'Annuler la demande';

  @override
  String get removeFriendTitle => 'Retirer un ami';

  @override
  String removeFriendBody(String name) {
    return 'Retirer $name de vos amis ?';
  }

  @override
  String get deleteShort => 'Retirer';

  @override
  String get requestDeclined => 'Demande refusée';

  @override
  String get friendRemoved => 'Ami retiré';

  @override
  String get requestWithdrawn => 'Demande annulée';

  @override
  String get retryAction => 'Réessayer';

  @override
  String get listFetchFailed => 'Impossible de charger la liste.';

  @override
  String get nobodyBlocked => 'Personne n\'est bloqué.';

  @override
  String get unblock => 'Débloquer';

  @override
  String get requestSent => 'Demande envoyée';

  @override
  String get addByTagHint =>
      'Demandez à votre ami son code (6 caractères) sur son profil.';

  @override
  String get sendRequest => 'Envoyer la demande';

  @override
  String get storeFetchFailed => 'Impossible de charger la boutique';

  @override
  String bundlePurchased(int qty, String gift) {
    return 'Vous avez reçu $qty× $gift';
  }

  @override
  String notEnoughForBundle(int price) {
    return 'Diamants insuffisants — le pack coûte $price💎';
  }

  @override
  String get purchaseFailed => 'Achat impossible';

  @override
  String get connectionFailed => 'Connexion impossible';

  @override
  String get unlimitedEnjoy => 'Jeu illimité — profitez-en !';

  @override
  String notEnoughForTicket(int price) {
    return 'Diamants insuffisants — le pass coûte $price💎';
  }

  @override
  String get storeTitle => 'Boutique';

  @override
  String get retryShort => 'Réessayer';

  @override
  String get tabPlay => 'Jeu';

  @override
  String get tabGifts => 'Cadeaux';

  @override
  String get tabDiamonds => 'Diamants';

  @override
  String get storeEmpty => 'Aucun article en boutique pour le moment.';

  @override
  String get ticketsIntro =>
      'Jouez sans limite pendant toute la durée — vous et vos amis.';

  @override
  String get unlimitedActiveNotice =>
      'Votre jeu illimité est actif. Tout achat prolonge à partir de sa fin.';

  @override
  String get cheaperThanSevenDays => 'Moins cher que sept pass journaliers';

  @override
  String get ticketFullDay => 'Journée complète — 24 heures';

  @override
  String get ticketFullWeek => 'Semaine complète — 7 jours';

  @override
  String ticketDays(int days) {
    return '$days jours';
  }

  @override
  String ticketHours(int hours) {
    return '$hours heures';
  }

  @override
  String get giftsIntro => 'Achetez maintenant, offrez quand vous voulez.';

  @override
  String get diamondsIntro =>
      'Un diamant vaut une ouguiya. Plus le pack est grand, plus vous en avez.';

  @override
  String get bankilySoon => 'Paiement par Bankily — bientôt.';

  @override
  String bonusPct(int pct) {
    return 'Bonus $pct %';
  }

  @override
  String priceOuguiya(int price) {
    return '$price MRU';
  }

  @override
  String ownedCount(int count) {
    return 'Vous en avez $count';
  }

  @override
  String savePct(int pct) {
    return '-$pct %';
  }

  @override
  String get missionDailyPlay => 'Jouez trois parties';

  @override
  String get missionDailyWin => 'Gagnez une partie';

  @override
  String get missionDailyFriend => 'Jouez avec un ami';

  @override
  String get missionDailyGift => 'Offrez un cadeau';

  @override
  String get missionDailyFouja => 'Démasquez une fouja';

  @override
  String get missionWeeklyPlay => 'Jouez vingt parties';

  @override
  String get missionWeeklyWin => 'Gagnez dix parties';

  @override
  String get missionWeeklyFriend => 'Jouez trois parties avec un ami';

  @override
  String get missionWeeklyInvite => 'Invitez un ami à votre table';

  @override
  String get missionWeeklyGifts => 'Offrez dix cadeaux';

  @override
  String get missionWeeklyRoom => 'Créez un salon privé';

  @override
  String get missionWeeklyClean => 'Jouez dix parties sans fouja';

  @override
  String get missionsUnavailable =>
      'Les missions sont indisponibles pour le moment.';

  @override
  String get missionsFetchFailed => 'Impossible de charger les missions';

  @override
  String missionRewardClaimed(int diamonds, int xp) {
    return 'Vous avez reçu $diamonds💎 et $xp XP';
  }

  @override
  String get missionStateChanged => 'L\'état de la mission a changé';

  @override
  String get claimFailed => 'Récupération impossible';

  @override
  String get missionsDaily => 'Quotidiennes';

  @override
  String get missionsDailyReset => 'Réinitialisées chaque jour';

  @override
  String get missionsWeekly => 'Hebdomadaires';

  @override
  String get missionsWeeklyReset => 'Réinitialisées chaque lundi';

  @override
  String get xpSuffix => ' XP';

  @override
  String get claim => 'Récupérer';

  @override
  String get vipFetchFailed => 'Impossible de charger l\'abonnement';

  @override
  String get vipWelcome => 'Bienvenue dans le VIP !';

  @override
  String notEnoughForVip(int price) {
    return 'Diamants insuffisants — l\'abonnement coûte $price💎';
  }

  @override
  String get subscribeFailed => 'Abonnement impossible';

  @override
  String get vipExtend => 'Prolongez votre abonnement';

  @override
  String get vipChoosePlan => 'Choisissez votre formule';

  @override
  String get vipFrameNote => 'Votre cadre exclusif vous suit à chaque table';

  @override
  String vipActiveUntil(String date) {
    return 'Vous êtes VIP — jusqu\'au $date';
  }

  @override
  String get vipPerkRoom => 'Salon privé';

  @override
  String get vipPerkRoomSub =>
      'Votre salon, à vous et vos amis — nul autre n\'y entre.';

  @override
  String get vipPerkUnlimited => 'Jeu illimité';

  @override
  String get vipPerkUnlimitedSub =>
      'Oubliez la limite de cinq parties — jouez autant que vous voulez.';

  @override
  String vipPerkDiamonds(int gems) {
    return '$gems diamants chaque mois';
  }

  @override
  String get vipPerkDiamondsSub =>
      'Versés chaque mois tant que votre abonnement est actif.';

  @override
  String get vipPerkBadge => 'Badge VIP';

  @override
  String get vipPerkBadgeSub => 'Elle accompagne votre nom à chaque table.';

  @override
  String get vipGiftsTitle => 'Des cadeaux que nul autre ne possède';

  @override
  String get vipGiftsSub =>
      'Trois offerts chaque jour — toute la table les voit.';

  @override
  String get planYear => 'Une année entière';

  @override
  String get planMonth => 'Un mois';

  @override
  String saveVsMonthly(int pct) {
    return '-$pct % par rapport au mensuel';
  }

  @override
  String get ruleBasicsTitle => 'Les bases';

  @override
  String get ruleBasicsBody =>
      'Quatre joueurs, deux équipes (les sièges 0 et 2 contre 1 et 3). 32 cartes (du 7 à l\'As). Le jeu tourne dans le sens inverse des aiguilles d\'une montre — le suivant est à votre droite.';

  @override
  String get ruleDealTitle => 'La donne';

  @override
  String get ruleDealBody =>
      'On distribue 3 puis 2, vient le tour de contrat, puis 3 dernières (8 par joueur). Le joueur à la droite du donneur annonce et entame le premier, et devient donneur de la manche suivante.';

  @override
  String get ruleBidTitle => 'Le contrat';

  @override
  String get ruleBidBody =>
      'Un seul tour exactement (4 annonces). Le premier joueur ne peut pas passer. On ne fait que monter — aucun nouveau tour après une enchère. La couleur annoncée devient l\'atout.';

  @override
  String get ruleAkwinsTitle => 'La Coinche';

  @override
  String get ruleAkwinsBody =>
      'Réservée à l\'adversaire, et seulement à son tour — elle clôt le contrat aussitôt et double la valeur de la manche (32 à la couleur · 52 en SA/TA).';

  @override
  String get rulePlayTitle => 'Le jeu';

  @override
  String get rulePlayBody =>
      'Si vous avez la couleur demandée, vous devez la fournir. Sinon, jouez la carte de votre choix — vous n\'êtes obligé ni de couper à l\'atout ni de surcouper.';

  @override
  String get ruleUnitsTitle => 'Les points de cartes';

  @override
  String get ruleUnitsBody =>
      'À l\'atout : V=20 et 9=14. À la couleur ordinaire : V=2 et 9=0. L\'As vaut 11, le 10 vaut 10, R=4, D=3, et 8/7 valent zéro. En SA/TA, toutes les couleurs suivent le barème de l\'atout.';

  @override
  String get ruleFoujaTitle => 'La fouja (renonce)';

  @override
  String get ruleFoujaBody =>
      'Ne pas fournir la couleur alors qu\'on la possède. L\'adversaire peut la réclamer dès qu\'il la découvre ; si elle est avérée, il empoche toute la valeur du contrat, et si l\'accusation est fausse, elle revient au camp adverse. La manche s\'arrête aussitôt.';

  @override
  String get ruleWinTitle => 'La victoire';

  @override
  String get ruleWinBody =>
      'Le premier à atteindre 100 points, et le plus haut, gagne la partie. En cas d\'égalité à 100 ou plus, on joue une manche décisive.';

  @override
  String get momentMvp => 'Homme du match';

  @override
  String get momentBestBid => 'Meilleur contrat';

  @override
  String momentBestBidDetail(int points, int round) {
    return '$points points marqués à la manche $round';
  }

  @override
  String get momentStrongestCard => 'Carte la plus forte';

  @override
  String momentStrongestCardDetail(int units) {
    return '$units points de cartes raflés en un seul pli';
  }

  @override
  String get momentLongestStreak => 'Plus longue série';

  @override
  String momentLongestStreakDetail(int count) {
    return '$count plis d\'affilée sans être coupé';
  }

  @override
  String get matchMoments => 'Moments de la partie';

  @override
  String tricksCount(int count) {
    return '$count plis';
  }

  @override
  String unitsCount(int count) {
    return '$count points de cartes';
  }

  @override
  String bidsWonCount(int count) {
    return '$count contrats réussis';
  }

  @override
  String foujaCaughtCount(int count) {
    return '$count foujas démasquées';
  }

  @override
  String bidWithAkwinsShort(String bid) {
    return '$bid coinché';
  }

  @override
  String youSuffix(String name) {
    return '$name (vous)';
  }

  @override
  String get authTagline => 'Jouez avec vos amis dans le monde entier';

  @override
  String get createAccount => 'Créer un compte';

  @override
  String get desktopAuthNote =>
      'Ici, création de compte et réinitialisation du mot de passe pour les numéros mauritaniens (+222) ; les autres numéros depuis l\'application mobile. La connexion fonctionne pleinement.';

  @override
  String get continueAsGuest => 'Continuer en invité';

  @override
  String get invalidPhone => 'Saisissez un numéro de téléphone valide';

  @override
  String get phoneAuthUnsupported =>
      'La connexion par téléphone n\'est pas prise en charge sur cette plateforme';

  @override
  String get enterSixDigitCode => 'Saisissez le code à 6 chiffres';

  @override
  String get passwordTooShort =>
      'Le mot de passe doit faire au moins 6 caractères';

  @override
  String get enterPassword => 'Saisissez votre mot de passe';

  @override
  String get enterYourName => 'Saisissez votre nom';

  @override
  String get enterYourCity => 'Saisissez votre ville';

  @override
  String get resetPasswordTitle => 'Réinitialiser le mot de passe';

  @override
  String get resetPasswordSub => 'Saisissez votre numéro pour recevoir un code';

  @override
  String get sendCode => 'Envoyer le code';

  @override
  String get codeTitle => 'Code de confirmation';

  @override
  String codeSentTo(String phone) {
    return 'Saisissez le code envoyé au $phone';
  }

  @override
  String get verify => 'Vérifier';

  @override
  String get newPasswordTitle => 'Nouveau mot de passe';

  @override
  String get newPasswordSub => 'Choisissez un nouveau mot de passe';

  @override
  String get saveAndSignIn => 'Enregistrer et se connecter';

  @override
  String get fieldPhone => 'Numéro de téléphone';

  @override
  String get fieldNewPassword => 'Nouveau mot de passe';

  @override
  String get fieldPassword => 'Mot de passe';

  @override
  String get fieldPasswordMin => 'Mot de passe (6 caractères minimum)';

  @override
  String get fieldName => 'Nom';

  @override
  String get fieldCity => 'Ville / région';

  @override
  String get loginSub =>
      'Connectez-vous avec votre numéro et votre mot de passe';

  @override
  String get forgotPassword => 'Mot de passe oublié ?';

  @override
  String get noAccountCreateOne => 'Pas de compte ? Créez-en un';

  @override
  String get haveAccountSignIn => 'Déjà un compte ? Connectez-vous';

  @override
  String get registerPhoneSub =>
      'Nous enverrons un code pour confirmer votre numéro';

  @override
  String get completeAccount => 'Complétez votre compte';

  @override
  String get completeAccountSub =>
      'Un mot de passe pour vos prochaines connexions, votre nom, votre pays et votre ville';

  @override
  String get createAccountAction => 'Créer le compte';

  @override
  String get dmConnectionFailed => 'Connexion au serveur impossible.';

  @override
  String get sendFailed => 'Envoi impossible — vérifiez votre connexion.';

  @override
  String blockTitle(String name) {
    return 'Bloquer $name ?';
  }

  @override
  String get blockBody =>
      'Il est retiré de vos amis, ne peut plus vous écrire ni vous inviter, et ses messages ne vous parviennent plus à la table.';

  @override
  String get blockConfirm => 'Bloquer';

  @override
  String get reportPlayerMenu => 'Signaler le joueur';

  @override
  String get blockMenu => 'Bloquer';

  @override
  String get writeMessageHint => 'Écrivez un message…';

  @override
  String get noMessagesYet => 'Aucun message — lancez la conversation.';

  @override
  String reportAbout(String name) {
    return 'Signaler $name';
  }

  @override
  String get reportNote =>
      'Le signalement parvient à l\'équipe du jeu, qui l\'examine elle-même.';

  @override
  String get reportHint => 'Que s\'est-il passé ? (facultatif)';

  @override
  String get giftRose => 'Rose';

  @override
  String get giftTea => 'Thé';

  @override
  String get giftSweet => 'Bonbon';

  @override
  String get giftCrown => 'Couronne';

  @override
  String get giftCamel => 'Chameau';

  @override
  String get giftCar => 'Voiture';

  @override
  String get giftVipFlower => 'Rose VIP';

  @override
  String get giftVipBox => 'Coffret VIP';

  @override
  String get giftVipPitcher => 'Théière VIP';

  @override
  String get giftTitle => 'Offrir';

  @override
  String get giftHumansOnly =>
      'Les cadeaux sont réservés aux joueurs humains — seule l\'IA est à votre table.\nInvitez un ami à une table privée pour lui offrir un cadeau.';

  @override
  String get giftToWhom => 'À qui ?';

  @override
  String get giftToAll => 'À tous';

  @override
  String get vipGifts => 'Cadeaux VIP';

  @override
  String remainingCount(int count) {
    return 'Reste $count';
  }

  @override
  String get giftWhat => 'Quel cadeau ?';

  @override
  String giftAllCostNote(int count) {
    return 'Le cadeau part vers $count joueurs — son prix est débité pour chacun.';
  }

  @override
  String get giftCostNote => 'Le prix est débité de vos diamants.';

  @override
  String get claimFailedRetry => 'Récupération impossible — réessayez';

  @override
  String get activateFailedRetry => 'Activation impossible — réessayez';

  @override
  String get giftDayTitle => 'Cadeau de notre part : une journée entière';

  @override
  String get openFullDayTitle => 'Débloquez une journée entière';

  @override
  String get playLimitGiftBody =>
      'Vos cinq parties du jour sont épuisées — et c\'est la première fois. Voici 24 heures illimitées offertes : jouez autant que vous voulez avec vos amis.';

  @override
  String get playLimitPlainBody =>
      'Vos parties du jour sont épuisées — elles reviennent demain.';

  @override
  String get playLimitOfferBody =>
      'Vos cinq parties du jour sont épuisées. Activez le jeu illimité pendant 24 heures et jouez autant que vous voulez avec vos amis.';

  @override
  String get offlineAlwaysFree =>
      'Le jeu contre l\'IA reste gratuit et illimité.';

  @override
  String get claimGift => 'Recevoir le cadeau';

  @override
  String get activateNow => 'Activer';

  @override
  String get yourTable => 'Votre table';

  @override
  String get seatRoleYou => 'Vous';

  @override
  String get seatRoleYourPartner => 'votre partenaire';

  @override
  String get seatRoleYourOpponent => 'votre adversaire';

  @override
  String get inviteShort => 'Inviter';

  @override
  String whoSitsHere(String role) {
    return 'Qui prend cette place ($role) ?';
  }

  @override
  String get noFriendsAddByTag =>
      'Aucun ami pour l\'instant. Ajoutez le vôtre avec son code depuis l\'écran Amis.';

  @override
  String get noFriendOnlineInviteAnyway =>
      'Aucun ami en ligne — invitez-le quand même, il recevra une notification.';

  @override
  String get offlineGroup => 'Hors ligne';

  @override
  String get offlineWillBeNotified => 'Hors ligne — recevra une notification';

  @override
  String get welcomeTitle => 'Bienvenue';

  @override
  String get welcomeGiftsBody =>
      'Voici notre cadeau — offrez-le à vos partenaires de jeu.';

  @override
  String get thanks => 'Merci';

  @override
  String get aboutGameTitle => 'Belote';

  @override
  String get aboutMauritanianEdition => 'Édition mauritanienne';

  @override
  String get aboutSection => 'À propos du jeu';

  @override
  String get aboutBody =>
      'La belote telle qu\'on la joue en Mauritanie : quatre joueurs, deux équipes, un contrat en un seul tour, et la Coinche réservée à l\'adversaire à son tour. Toutes les règles sont dans « Comment jouer ».';

  @override
  String get aboutDevSection => 'Développement';

  @override
  String get aboutMadeWithLove =>
      'Faite avec passion pour le jeu de chez nous 🃏';

  @override
  String get aboutVersionSection => 'Version de l\'application';

  @override
  String get appInitial => 'B';

  @override
  String get giveGift => 'Lui offrir';

  @override
  String unmutePlayer(String name) {
    return 'Réactiver $name';
  }

  @override
  String mutePlayer(String name) {
    return 'Couper $name';
  }

  @override
  String get relFriend => 'Votre ami';

  @override
  String get relOutgoing => 'En attente de sa réponse';

  @override
  String get relIncoming => 'Accepter sa demande';

  @override
  String get relAdd => 'Ajouter en ami';

  @override
  String get signInToWatch => 'Connectez-vous pour regarder les parties.';

  @override
  String get liveFetchFailed =>
      'Impossible de charger les parties — vérifiez votre connexion.';

  @override
  String get refresh => 'Actualiser';

  @override
  String get tournamentChip => 'Tournoi';

  @override
  String get versusShort => 'contre';

  @override
  String get watchMatch => 'Regarder la partie';

  @override
  String updateNewVersion(String version) {
    return 'Nouvelle version $version';
  }

  @override
  String get updateAvailable =>
      'Une version plus récente du jeu est disponible.';

  @override
  String get updateFailed => 'Mise à jour impossible';

  @override
  String get installing => 'Installation…';

  @override
  String downloading(int percent) {
    return 'Téléchargement… $percent %';
  }

  @override
  String get updateNow => 'Mettre à jour';

  @override
  String get voiceLive => 'Micro ouvert — appuyez pour couper';

  @override
  String get voiceConnecting => 'Connexion…';

  @override
  String get voiceFailed => 'Micro indisponible — appuyez pour réessayer';

  @override
  String get voiceOff => 'Micro coupé — appuyez pour parler';

  @override
  String get giftToAllTip => 'Cadeau pour tous';

  @override
  String giftToPlayer(String name) {
    return 'Cadeau pour $name';
  }

  @override
  String get markAllRead => 'Tout marquer comme lu';

  @override
  String get agoNow => 'À l\'instant';

  @override
  String agoMinutes(int count) {
    return 'il y a $count min';
  }

  @override
  String agoHours(int count) {
    return 'il y a $count h';
  }

  @override
  String agoDays(int count) {
    return 'il y a $count j';
  }

  @override
  String get honorBoardWeek => 'Tableau d\'honneur — cette semaine';

  @override
  String get seeAll => 'Tout voir';

  @override
  String get honorBoardNote =>
      'Le premier de chaque catégorie porte son titre toute la semaine suivante — visible par tous ses partenaires de table.';

  @override
  String get honorBoard => 'Tableau d\'honneur';

  @override
  String get playerCardDemo => 'Carte du joueur';

  @override
  String get playerCardDemoSub => 'Normale · active (joueur au tour)';

  @override
  String rankNextTitle(String title, String next) {
    return '$title · prochain : $next';
  }

  @override
  String get leaderboardFetchFailed => 'Impossible de charger le classement';

  @override
  String get leaderboardEmpty =>
      'Pas encore de classement — jouez en ligne pour y figurer.';

  @override
  String matchesAndWins(int matches, int wins) {
    return '$matches parties · $wins victoires';
  }

  @override
  String get chatTitle => 'Discussion';

  @override
  String get vipUpsellTitle => 'Et si vous passiez VIP ?';

  @override
  String get vipUpsellBody =>
      'Vous achetez souvent des pass — un mois complet de VIP coûte le prix de dix pass seulement, avec le jeu illimité, un salon privé, des cadeaux exclusifs et 50💎 chaque mois.';

  @override
  String get seeVip => 'Découvrir le VIP';

  @override
  String get friendFallback => 'Votre ami';

  @override
  String invitesYou(String name) {
    return '$name vous invite';
  }

  @override
  String get inviteToPrivateTable =>
      'À sa table privée — une place vous est réservée.';

  @override
  String get nameEntryPrompt =>
      'Bienvenue — saisissez votre nom pour commencer';

  @override
  String get nameHint => 'Votre nom';

  @override
  String get start => 'Commencer';

  @override
  String profileOf(String name) {
    return 'Profil de $name';
  }

  @override
  String get messagesTip => 'Messages';

  @override
  String get latestNews => 'Dernières nouvelles';

  @override
  String rankedMatchesLeft(int count) {
    return 'Encore $count parties classées avant d\'être classé';
  }

  @override
  String get ratingLabel => 'Classement ';

  @override
  String rankedMatchesLeftLong(int count) {
    return 'Encore $count parties classées pour obtenir votre rang';
  }

  @override
  String get rankTopReached =>
      'Vous êtes au sommet — une Légende défend son rang, elle ne monte plus';

  @override
  String rankPointsToNext(String title, int points) {
    return 'Vers $title : $points points de classement';
  }

  @override
  String get reportAction => 'Signaler';

  @override
  String pointsCount(int count) {
    return '$count points';
  }

  @override
  String get developerName => 'Mohamed Lemine / Tegra / Beine';

  @override
  String get languageArabicNative => 'العربية';

  @override
  String get demoNameOne => 'Ahmedou';

  @override
  String get demoNameTwo => 'El Moctar';

  @override
  String get demoNameThree => 'Sidi Ahmed';

  @override
  String get demoNameFour => 'Babah';

  @override
  String get errFriendInvalidTag =>
      'Code invalide — 6 caractères, tels qu\'ils apparaissent sur le profil de votre ami.';

  @override
  String get errFriendNotFound => 'Aucun joueur avec ce code. Vérifiez-le.';

  @override
  String get errFriendSelf => 'C\'est votre propre code.';

  @override
  String get errFriendAlready =>
      'Une demande ou une amitié existe déjà entre vous.';

  @override
  String get errFriendNoRequest =>
      'Aucune demande de ce joueur n\'attend votre réponse.';

  @override
  String get errFriendNotFriend => 'Vous n\'avez aucun lien avec ce joueur.';

  @override
  String get errMessageNotFriend =>
      'Les messages sont réservés aux amis — ajoutez-le d\'abord.';

  @override
  String get errMessageBlocked => 'Impossible d\'écrire à ce joueur.';

  @override
  String get errMessageEmpty => 'Écrivez d\'abord un message.';

  @override
  String get errBlockNotFound => 'Joueur introuvable.';

  @override
  String get errBlockSelf => 'Vous ne pouvez pas vous bloquer vous-même.';

  @override
  String get errAvatarTooLarge =>
      'Image trop lourde. Choisissez-en une plus petite.';

  @override
  String get errAvatarBadType =>
      'Ce n\'est pas une image. Choisissez un fichier JPG ou PNG.';

  @override
  String get errAvatarEmpty => 'Le fichier est vide.';

  @override
  String get errTrnClosed =>
      'Un tournoi est en cours — les inscriptions rouvrent à sa fin.';

  @override
  String get errTrnAlreadyRegistered => 'Vous êtes déjà inscrit.';

  @override
  String get errTrnNotRegistered => 'Vous n\'êtes pas inscrit à ce tournoi.';

  @override
  String get errTrnFull => 'Complet — un prochain tournoi ouvrira bientôt.';

  @override
  String get errTrnInsufficient =>
      'Vos diamants ne couvrent pas la mise d\'entrée.';

  @override
  String get errTrnNotFriends =>
      'Le partenariat est réservé aux amis — ajoutez-le d\'abord.';

  @override
  String get errTrnPairTaken =>
      'L\'un de vous a déjà un partenaire ou une invitation en cours.';

  @override
  String get errTrnNoInvite => 'Aucune invitation de partenariat en cours.';

  @override
  String get errTrnBadRequest => 'Demande invalide.';

  @override
  String get errTrnHasActiveEvent =>
      'Vous avez déjà un tournoi en cours — terminez-le ou annulez-le d\'abord.';

  @override
  String get errTrnBadTitle => 'Le nom doit faire de 3 à 30 caractères.';

  @override
  String get errTrnBadFee => 'La mise d\'entrée va de 10 à 500 diamants.';

  @override
  String get errTrnBadTeams => 'Taille : 8 ou 16 équipes.';

  @override
  String get errTrnBadTime =>
      'La date doit être entre 10 minutes et 7 jours à partir de maintenant.';

  @override
  String get chatSalam => 'Salam aleikoum';

  @override
  String get chatNice => 'Joli coup';

  @override
  String get chatBravo => 'Bravo';

  @override
  String get chatLuck => 'Bonne chance';

  @override
  String get chatHurry => 'Un peu plus vite';

  @override
  String get chatSorry => 'Désolé';

  @override
  String get chatThanks => 'Merci';

  @override
  String get chatBye => 'À bientôt';

  @override
  String get guestOnlineTitle => 'Jouer en ligne';

  @override
  String get guestOnlineBody =>
      'Créez un compte pour jouer avec de vrais joueurs et conserver votre progression et vos diamants.';

  @override
  String get spectator => 'Spectateur';

  @override
  String giftSentTo(String from, String to) {
    return '$from a offert un cadeau à $to';
  }

  @override
  String get voiceNotEnabled =>
      'La voix n\'est pas encore activée sur le serveur.';

  @override
  String get voiceNotAtTable => 'Vous n\'êtes à aucune table.';

  @override
  String get voiceSessionOver => 'Votre session a expiré — reconnectez-vous.';

  @override
  String get voiceConnectFailed =>
      'Connexion à la voix impossible. Vérifiez l\'autorisation du micro et le réseau.';

  @override
  String get errUnexpectedShort => 'Erreur inattendue';

  @override
  String get errPhoneInvalid => 'Numéro de téléphone invalide';

  @override
  String get errCodeInvalid => 'Code invalide';

  @override
  String get errCodeExpired => 'Code expiré — demandez-en un nouveau';

  @override
  String get errTooManyAttempts => 'Trop de tentatives — réessayez plus tard';

  @override
  String get errQuotaExceeded => 'Quota dépassé — réessayez plus tard';

  @override
  String get errNetwork => 'Connexion réseau impossible';

  @override
  String get errVerifyFailed => 'Échec de la vérification';

  @override
  String get errNoCodeSent => 'Aucun code n\'a encore été envoyé';

  @override
  String get errTokenFailed => 'Impossible d\'émettre le jeton de connexion';

  @override
  String get errInstallAndroidOnly =>
      'L\'installation intégrée n\'est prise en charge que sur Android';

  @override
  String get errInstallPermission =>
      'Activez « Autoriser cette source » puis réessayez';

  @override
  String errDownloadFailed(int code) {
    return 'Échec du téléchargement (code $code)';
  }

  @override
  String get errDownloadIncomplete =>
      'Téléchargement incomplet — réessayez plus tard';

  @override
  String errInstallerOpen(String reason) {
    return 'Impossible d\'ouvrir l\'installateur ($reason)';
  }

  @override
  String get errUpdateGeneric =>
      'Mise à jour impossible — vérifiez la connexion et réessayez';

  @override
  String get bankilyBuy => 'Acheter via Bankily';

  @override
  String get bankilySoonBadge => 'Bientôt';

  @override
  String get bankilyTitle => 'Paiement via Bankily';

  @override
  String get bankilySoonBanner =>
      'Le paiement Bankily arrive bientôt. Voici les étapes ; le bouton de confirmation fonctionnera dès son activation — sans mise à jour de l\'application.';

  @override
  String bankilyStepOf(int step) {
    return 'Étape $step sur 4';
  }

  @override
  String get bankilyStep1Title => 'Ouvrez Bankily';

  @override
  String get bankilyStep1Body =>
      'Ouvrez Bankily sur votre téléphone et allez dans B-PAY.';

  @override
  String get bankilyStep2Title => 'Saisissez le code commerçant et le montant';

  @override
  String get bankilyStep2Body =>
      'Dans B-PAY, saisissez le code commerçant et le montant exactement comme ici.';

  @override
  String get bankilyMerchantCode => 'Code commerçant';

  @override
  String get bankilyAmount => 'Montant';

  @override
  String get bankilyStep3Title => 'Recevez le code';

  @override
  String get bankilyStep3Body =>
      'Bankily vous envoie un code à 4 chiffres pour confirmer l\'opération.';

  @override
  String get bankilyStep4Title => 'Finalisez le paiement';

  @override
  String get bankilyStep4Body =>
      'Saisissez votre numéro Bankily et le code reçu.';

  @override
  String get bankilyPhone => 'Numéro Bankily';

  @override
  String get bankilyCode => 'Code reçu de Bankily';

  @override
  String get bankilyConfirm => 'Confirmer le paiement';

  @override
  String get bankilyNext => 'Continuer';

  @override
  String get bankilyBack => 'Retour';

  @override
  String get bankilyCopied => 'Copié';

  @override
  String bankilyYouGet(int diamonds) {
    return 'Vous recevrez $diamonds diamants';
  }

  @override
  String bankilySuccess(int diamonds) {
    return 'Diamants reçus ! $diamonds diamants ajoutés à votre solde.';
  }

  @override
  String get bankilyErrPhone => 'Numéro à 8 chiffres commençant par 2, 3 ou 4';

  @override
  String get bankilyErrCode => 'Le code fait 4 chiffres';

  @override
  String get bankilyErrRejected =>
      'Bankily a refusé l\'opération — vérifiez le code et réessayez';

  @override
  String get bankilyErrUnreachable =>
      'Bankily est injoignable — réessayez dans un instant';

  @override
  String get devCredit => 'Conception et développement';

  @override
  String get devName => 'Mohamed Leminne Beine';

  @override
  String get bankilyTapToCopy => 'Touchez pour copier';

  @override
  String get storeBuyChoose => 'Choisissez le mode de paiement';

  @override
  String get storeBuyViaApple => 'Payer avec Apple';

  @override
  String get storeBuyViaGoogle => 'Payer avec Google Play';

  @override
  String get storeBuyViaStoreSub => 'Carte ou solde du store';

  @override
  String get storeBuyViaBankilySub => 'Depuis votre portefeuille Bankily';

  @override
  String get storeBuyCancelled => 'Opération annulée';

  @override
  String get storeBuyUnavailable =>
      'L\'achat via le store n\'est pas disponible pour le moment';

  @override
  String get storeBuyFailed =>
      'Achat impossible — si le montant a été débité, les diamants arriveront automatiquement à la prochaine ouverture de l\'application';

  @override
  String get pulseTopPlayers => 'Meilleurs joueurs';

  @override
  String get pulseLiveNow => 'Parties en cours';

  @override
  String pulseWatchers(int count) {
    return '$count spectateurs';
  }

  @override
  String get pulseSeeAll => 'Tout voir';

  @override
  String get privacyPolicy => 'Politique de confidentialité';

  @override
  String get helpAndSupport => 'Aide et assistance';

  @override
  String get appStoreBuySoon => 'Achat via l\'App Store — bientôt.';

  @override
  String get errLoginFailed =>
      'Impossible de terminer la connexion. Réessayez.';

  @override
  String errCodeInvalidLeft(int count) {
    return 'Code invalide — $count tentatives restantes';
  }

  @override
  String errOtpRetryAfter(int seconds) {
    return 'Trop de demandes — réessayez dans $seconds s';
  }

  @override
  String get errOtpUnavailable =>
      'Le service SMS est indisponible pour le moment — réessayez bientôt';

  @override
  String get errPhoneTaken => 'Ce numéro a déjà un compte — connectez-vous';

  @override
  String get errPhoneUnknown => 'Aucun compte avec ce numéro';

  @override
  String resendCodeIn(int seconds) {
    return 'Renvoyer dans $seconds s';
  }

  @override
  String get resendCode => 'Renvoyer le code';

  @override
  String get sendViaWhatsApp => 'Envoyer le code par WhatsApp';
}
