import Foundation

/// Historical catalogue signatures distinguish untouched bundled messages from personal edits.
/// Keep retired signatures when changing or removing bundled content.
nonisolated enum LegacyAffirmationCatalog {
    private struct Signature {
        let id: String
        let text: String
        let tags: [String]
    }

    static func contains(id: UUID, text: String, tags: [String]) -> Bool {
        signatures.contains {
            $0.id == id.uuidString && $0.text == text
                && AffirmationTag.canonicalTags($0.tags) == AffirmationTag.canonicalTags(tags)
        }
    }

    private static let signatures: [Signature] = [
        Signature(id: "B7E77000-0000-4000-8000-000000000034", text: "You've got this, honey. The dramatic internal monologue can take five.", tags: ["confidence", "self-kindness"]),
        Signature(id: "B7E77000-0000-4000-8000-000000000035", text: "You've got this, {name}. Your doubts can shut up and watch.", tags: ["confidence"]),
        Signature(id: "B7E77000-0000-4000-8000-000000000036", text: "You're capable of more than your brain's shitty reviews suggest.", tags: ["confidence"]),
        Signature(id: "B7E77000-0000-4000-8000-000000000037", text: "Walk in like you belong. Nobody appointed your anxiety the bouncer.", tags: ["confidence"]),
        Signature(id: "B7E77000-0000-4000-8000-000000000038", text: "You don't need everyone's approval. Half of them can't even choose a fucking restaurant.", tags: ["confidence"]),
        Signature(id: "B7E77000-0000-4000-8000-000000000039", text: "Take up space, honey. You didn't come this far to apologise for existing.", tags: ["confidence", "body"]),
        Signature(id: "B7E77000-0000-4000-8000-000000000015", text: "Stop comparing. You're the only {name} in the room.", tags: ["confidence"]),
        Signature(id: "B7E77000-0000-4000-8000-000000000040", text: "You can be scared and still do the thing. Fear doesn't get casting rights.", tags: ["confidence"]),
        Signature(id: "B7E77000-0000-4000-8000-000000000041", text: "You don't need to be the loudest person in the room. Let the bullshit compete with itself.", tags: ["confidence"]),
        Signature(id: "B7E77000-0000-4000-8000-000000000042", text: "Start before you feel ready. Confidence is taking its sweet fucking time.", tags: ["confidence"]),
        Signature(id: "B7E77000-0000-4000-8000-000000000001", text: "“I'm full. The pantry doesn't need a follow-up visit.", tags: ["food"]),
        Signature(id: "B7E77000-0000-4000-8000-000000000002", text: "My cravings can make suggestions. They don't get to run the frikkin’ meeting.", tags: ["food"]),
        Signature(id: "B7E77000-0000-4000-8000-000000000004", text: "I enjoyed that. It doesn't mean I need an encore.", tags: ["food"]),
        Signature(id: "B7E77000-0000-4000-8000-000000000016", text: "I want another cookie. What a surprise. Doesn't mean I need one.", tags: ["food"]),
        Signature(id: "B7E77000-0000-4000-8000-000000000017", text: "The fridge isn't going to develop new content. Close it.", tags: ["food"]),
        Signature(id: "B7E77000-0000-4000-8000-000000000018", text: "Boredom wants a snack. Give the bastard something else to do.", tags: ["food"]),
        Signature(id: "B7E77000-0000-4000-8000-000000000019", text: "You can admire a cake without making it today's side quest.", tags: ["food"]),
        Signature(id: "B7E77000-0000-4000-8000-000000000020", text: "Free food isn't a summons. You can leave it there.", tags: ["food"]),
        Signature(id: "B7E77000-0000-4000-8000-000000000021", text: "Hungry? Eat. Bored? The snack cupboard is a shit hobby.", tags: ["food"]),
        Signature(id: "B7E77000-0000-4000-8000-000000000022", text: "{name}, is it hunger, or are you just flirting with the fridge?", tags: ["food"]),
        Signature(id: "B7E77000-0000-4000-8000-000000000006", text: "Gay looks good on you. Anyone bothered can look elsewhere.", tags: ["gay", "confidence"]),
        Signature(id: "B7E77000-0000-4000-8000-000000000007", text: "The straight instruction manual is full of plot holes. Write your own fucking life.", tags: ["gay"]),
        Signature(id: "B7E77000-0000-4000-8000-000000000008", text: "You don't owe anyone a convincing performance of gay. There's no fucking audition.", tags: ["gay"]),
        Signature(id: "B7E77000-0000-4000-8000-000000000009", text: "You like men. Excellent taste. Questionable group chat, probably.", tags: ["gay"]),
        Signature(id: "B7E77000-0000-4000-8000-000000000010", text: "Be as gay as you damn well please. Nobody needs a quieter version.", tags: ["gay"]),
        Signature(id: "B7E77000-0000-4000-8000-000000000023", text: "You're not everyone's cup of tea. Stop watering yourself down for people with no taste.", tags: ["gay"]),
        Signature(id: "B7E77000-0000-4000-8000-000000000024", text: "Coming out wasn't an invitation for a fucking panel discussion.", tags: ["gay"]),
        Signature(id: "B7E77000-0000-4000-8000-000000000025", text: "You don't owe anyone a watered-down version of yourself. They can choke on the full flavour.", tags: ["gay"]),
        Signature(id: "B7E77000-0000-4000-8000-000000000026", text: "Your gay card is fine. The committee in your head can fuck off.", tags: ["gay"]),
        Signature(id: "B7E77000-0000-4000-8000-000000000027", text: "{name}, you're gay enough. The imaginary membership board can get fucked.", tags: ["gay", "self-kindness"]),
        Signature(id: "B7E77000-0000-4000-8000-000000000011", text: "Hey {name}, you're allowed to like what you see. The mirror police aren't real.", tags: ["body"]),
        Signature(id: "B7E77000-0000-4000-8000-000000000012", text: "Your body isn't a public consultation. The comments are closed.", tags: ["body"]),
        Signature(id: "B7E77000-0000-4000-8000-000000000013", text: "You don't need abs to deserve someone's hands on you.", tags: ["body"]),
        Signature(id: "B7E77000-0000-4000-8000-000000000014", text: "Grey hairs, honey. Your head has receipts.", tags: ["body"]),
        Signature(id: "B7E77000-0000-4000-8000-000000000028", text: "Your reflection doesn't need another shitty performance review. Find something nice to say.", tags: ["body", "self-kindness"]),
        Signature(id: "B7E77000-0000-4000-8000-000000000029", text: "Your body got you through some shit. Give it more than a list of complaints.", tags: ["body"]),
        Signature(id: "B7E77000-0000-4000-8000-000000000030", text: "You're someone's type. Your brain's terrible marketing doesn't change that.", tags: ["body", "confidence"]),
        Signature(id: "B7E77000-0000-4000-8000-000000000031", text: "Your underwear size isn't a verdict. It's information for buying fucking underwear.", tags: ["body"]),
        Signature(id: "B7E77000-0000-4000-8000-000000000032", text: "The mirror didn't start this argument. Put the insults down.", tags: ["body"]),
        Signature(id: "B7E77000-0000-4000-8000-000000000033", text: "You don't need to look like a Greek god to take your shirt off.", tags: ["body"]),
        Signature(id: "B7E77000-0000-4000-8000-000000000043", text: "Give yourself a break, honey. The unpaid bully shift is over.", tags: ["self-kindness"]),
        Signature(id: "B7E77000-0000-4000-8000-000000000044", text: "Good god girl, get a grip!", tags: ["self-kindness"]),
        Signature(id: "B7E77000-0000-4000-8000-000000000045", text: "Have an off day. You don't need to turn it into a fucking identity.", tags: ["self-kindness"]),
        Signature(id: "B7E77000-0000-4000-8000-000000000046", text: "You fucked up. Fix what you can. The self-loathing isn't helping with the paperwork.", tags: ["self-kindness"]),
        Signature(id: "B7E77000-0000-4000-8000-000000000047", text: "You don't have to earn kindness. This isn't a fucking loyalty scheme.", tags: ["self-kindness"]),
        Signature(id: "B7E77000-0000-4000-8000-000000000048", text: "Give yourself some credit. You've dealt with shit nobody else even saw.", tags: ["self-kindness"]),
        Signature(id: "B7E77000-0000-4000-8000-000000000049", text: "You're still figuring it out. So is everyone pretending they've got their shit together.", tags: ["self-kindness"]),
        Signature(id: "B7E77000-0000-4000-8000-000000000050", text: "<small>Let it go means to</small><br>Let it be", tags: ["self-kindness"]),
        Signature(id: "B7E77000-0000-4000-8000-000000000051", text: "Yesterday was a mess. You don't have to commission a sequel.", tags: ["self-kindness"]),
        Signature(id: "B7E77000-0000-4000-8000-000000000052", text: "Be on your own side, honey. The world has enough arseholes on the payroll.", tags: ["self-kindness"]),
        Signature(id: "B7E77000-0000-4000-8000-000000000053", text: "My brain is talking shit again. It doesn't make it true.", tags: ["inner-critic"]),
        Signature(id: "B7E77000-0000-4000-8000-000000000054", text: "A little peace and quiet would be nice. Especially from myself.", tags: ["inner-critic"]),
        Signature(id: "B7E77000-0000-4000-8000-000000000055", text: "I’m allowed to fuck up without deciding I’m a fuck-up.", tags: ["inner-critic"]),
        Signature(id: "B7E77000-0000-4000-8000-000000000056", text: "My inner critic has a loud mouth and questionable credentials.", tags: ["inner-critic"]),
        Signature(id: "B7E77000-0000-4000-8000-000000000057", text: "I’ve barely opened my eyes. The character assassination can wait.", tags: ["inner-critic"]),
        Signature(id: "B7E77000-0000-4000-8000-000000000058", text: "I don't have to be productive all the time. I'm a person, not an appliance.", tags: ["inner-critic"]),
        Signature(id: "B7E77000-0000-4000-8000-000000000059", text: "I can sort my shit out without treating myself like shit.", tags: ["inner-critic"]),
        Signature(id: "B7E77000-0000-4000-8000-000000000060", text: "My negative thoughts can file a formal complaint. The bin is accepting submissions.", tags: ["inner-critic"]),
        Signature(id: "B7E77000-0000-4000-8000-000000000061", text: "I’m backing myself today. The bitchy commentary can ride in the boot.", tags: ["inner-critic"]),
        Signature(id: "B7E77000-0000-4000-8000-000000000062", text: "I can regret what I did without putting my entire existence on trial.", tags: ["inner-critic"]),
        Signature(id: "B7E77000-0000-4000-8000-000000000063", text: "I could use a little tenderness. Yes, me. Don't make it weird.", tags: ["inner-critic"]),
        Signature(id: "B7E77000-0000-4000-8000-000000000064", text: "My inner bully thinks it's a life coach. I'm cancelling the subscription.", tags: ["inner-critic"]),
        Signature(id: "B7E77000-0000-4000-8000-000000000065", text: "Enjoy it, honey. You chose a treat, not a fucking tribunal.", tags: ["treat-yourself"]),
        Signature(id: "B7E77000-0000-4000-8000-000000000066", text: "Have the fucking cake. Enjoy it properly.", tags: ["treat-yourself"]),
        Signature(id: "B7E77000-0000-4000-8000-000000000067", text: "You ordered dessert, not a moral crisis.", tags: ["treat-yourself"]),
        Signature(id: "B7E77000-0000-4000-8000-000000000068", text: "A treat doesn't need an apology or a punishment workout.", tags: ["treat-yourself"]),
        Signature(id: "B7E77000-0000-4000-8000-000000000069", text: "Enjoy it. Tomorrow doesn't need a dramatic redemption arc.", tags: ["treat-yourself"]),
        Signature(id: "B7E77000-0000-4000-8000-000000000070", text: "This is a treat, honey. Put the guilt down and taste the damn thing.", tags: ["treat-yourself"]),
        Signature(id: "B7E77000-0000-4000-8000-000000000071", text: "You can enjoy dinner without giving your inner critic a seat at the table.", tags: ["treat-yourself"]),
        Signature(id: "B7E77000-0000-4000-8000-000000000072", text: "{name}, you don't owe anyone a defence of your dessert.", tags: ["treat-yourself"]),
        Signature(id: "B7E77000-0000-4000-8000-000000000073", text: "A good meal is allowed to be a good meal. Stop adding a side of self-loathing.", tags: ["treat-yourself"]),
        Signature(id: "B7E77000-0000-4000-8000-000000000074", text: "Enjoy what you chose. You can stop when you're satisfied; nobody's grading the performance.", tags: ["treat-yourself"]),
        Signature(id: "B7E77000-0000-4000-8000-000000000034", text: "You've got this, hun.", tags: ["confidence", "self-kindness"]),
        Signature(id: "B7E77000-0000-4000-8000-000000000035", text: "You've got this, {name}. Your doubts can just shut up.", tags: ["confidence"]),
        Signature(id: "B7E77000-0000-4000-8000-000000000043", text: "Give yourself a break, honey.", tags: ["self-kindness"]),
        Signature(id: "B7E77000-0000-4000-8000-000000000044", text: "Fuck it, let that shit go.", tags: ["self-kindness"]),
        Signature(id: "B7E77000-0000-4000-8000-000000000045", text: "I am<br><small>far more than</small><br>enough, bitch!", tags: ["self-kindness"]),
        Signature(id: "B7E77000-0000-4000-8000-000000000050", text: "<small>To let it go is to</small><br>Let it be.", tags: ["self-kindness"]),
        Signature(id: "B7E77000-0000-4000-8000-000000000052", text: "Be on your own side, honey. The world has enough arseholes.", tags: ["self-kindness"]),
        Signature(id: "B7E77000-0000-4000-8000-000000000053", text: "It's just the itty bitty shitty committee.<br>Ignore it!", tags: ["inner-critic"]),
        Signature(id: "B7E77000-0000-4000-8000-000000000055", text: "I can fuck up without being am a fuck-up.", tags: ["inner-critic"]),
        Signature(id: "B7E77000-0000-4000-8000-000000000056", text: "<small>To my inner critic:</small><br>Stop, just stop.", tags: ["inner-critic"]),
        Signature(id: "B7E77000-0000-4000-8000-000000000015", text: "Stop comparing. You're the only Brett in the room.", tags: ["confidence"]),
    ]
}
