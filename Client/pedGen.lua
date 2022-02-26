local hashTable = {
    Military = {
        female = {
        
        },
        male = {
            'CSB_Security_A',
            'IG_Vincent_3'
        }
    },
    Construction = {
        female = {
        
        },
        male = {
        
        }
    },
    Civ = {
        female = {
            'A_F_Y_StudioParty_01',
            'CSB_SoundEng_00',
            'S_F_M_StudioAssist_01',
            'a_f_m_bevhills_01',
            'a_f_m_bevhills_02',
            'a_f_m_business_02',
            'a_f_m_downtown_0',
            'a_f_m_eastsa_01',
            'a_f_m_eastsa_02', -- frist row https://docs.fivem.net/docs/game-references/ped-models/
        },
        male = {
            'A_M_M_StudioParty_01',
            'CSB_Billionaire',
            'CSB_JIO_02',
            'CSB_MJO_02',
            'CSB_Party_Promo',
            'S_M_M_HighSec_05',
            'S_M_M_StudioAssist_02',
            'S_M_M_StudioProd_01',
            'S_M_M_StudioSouEng_02'
        }
    },
    Gang = {
        female = {
            'A_F_Y_StudioParty_02',
            'A_F_Y_StudioParty_01',
            'IG_Entourage_A',
            'IG_Entourage_B'
        },
        male = {
            'A_M_Y_StudioParty_01',
            'CSB_Ballas_Leader',
            'CSB_Musician_00',
            'CSB_Req_Officer',
            'CSB_Vagos_Leader',
            'G_M_M_Goons_01',
            'IG_Johnny_Guns'
        }
    },
    Sport = {
        female = {
            'A_F_Y_StudioParty_02',
        },
        male = {
            'CSB_Golfer_A',
            'CSB_Golfer_B',
        }
    },
    Story = {
        female = {
            'CSB_Imani',
        },
        male = {
            'CS_LamarDavis_02',
            'CSB_Vernon',
            'CSB_ARY_02',
        }
    }
}

function genRandomPed(gender, category)
    for category, gender in pairs(hashTable) do
        if category == category and gender == gender then
            return gender
        end
    end
end
