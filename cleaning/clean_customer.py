# type: ignore
# Import Required Libraries
from typing import Dict, List, Tuple
import pandas as pd


def clean_customer_csv(out: str):
    def get_cust_df(file_path: str = './data/Customer.csv', encoding: str = 'latin'):
        with open(file=file_path, mode='rb') as f:

            # Get contents of file in binary
            contents = f.read()

            # Skip redundant characters at the beginning
            # Remove null characters
            # Split records by newline characters (\r\n)
            list_of_records_str = contents[2:].replace(
                b'\x00', b'').split(b'\r\n')

            # Remove redundant characters at the end
            list_of_records_str.pop()

            # Rectify erroneous placement of pipe (|) separator
            header = list_of_records_str[0]
            header = header[:20] + b'|' + header[20:29] + header[30:]
            list_of_records_str[0] = header

            # Split each record into cells by pipe character
            list_of_records_list = []
            for i in list_of_records_str:
                list_of_records_list.append(
                    i.decode(encoding=encoding).split('|'))

            # Create DataFrame
            # Populate DataFrame with the given data
            df = pd.DataFrame(
                data=list_of_records_list[1:], columns=list_of_records_list[0])

            # Set the index of the DataFrame (optional)
            df.set_index(keys='CustomerId', inplace=True)

            return df

    # Load data
    df = get_cust_df()

    # Replace empty strings with None
    df.replace(to_replace={'': None}, inplace=True)

    # Standardize USA to United States
    df['Country'] = df['Country'].replace(to_replace={'USA': 'United States'})

    # Expand state codes

    # Do note that each country has its own version (state/province/region/county)
    # Specifically, they are as follows:
    #   Australia:      state
    #   Brazil:         state
    #   Canada:         province
    #   France:         region
    #   Italy:          region
    #   Netherlands:    province
    #   UK:             county
    #   US:             state

    # Expand non-overlapping codes
    df['State'] = df['State'].replace(to_replace={
        'SP': 'S\xe3o Paulo',       # Brazil (3)
        'RJ': 'Rio de Janeiro',
        'DF': 'Distrito Federal',
        'QC': 'Quebec',             # Canada (12)
        'AB': 'Alberta',
        'BC': 'British Columbia',
        'ON': 'Ontario',
        'NS': 'Nova Scotia',
        'MB': 'Manitoba',
        'NT': 'Northwest Territories',
        'YT': 'Yukon',
        'NB': 'New Brunswick',
        'NL': 'Newfoundland and Labrador',
        'NU': 'Nunavut',
        'SK': 'Saskatchewan',
        'BA': 'Normandy',           # France (5)
        'AQ': 'Nouvelle-Aquitaine',
        # 'IL': '\xcele-de-France',   # Clash with US
        'MI': 'Occitanie',
        'LO': 'Grand Est',
        'RM': 'Lazio',              # Italy (7)
        'VEN': 'Veneto',
        'BAS': 'Basilicata',
        'CAM': 'Campania',
        'SAR': 'Sardinia',
        'PIE': 'Piedmont',
        'CAL': 'Calabria',
        'CA': 'California',         # US (15)
        'WA': 'Washington',
        'NY': 'New York',
        'NV': 'Nevada',
        # 'FL': 'Florida',            # Clash with UK
        'MA': 'Massachusetts',
        # 'IL': 'Illinois',           # Clash with France
        'WI': 'Wisconsin',
        'TX': 'Texas',
        'AZ': 'Arizona',
        'UT': 'Utah',
        'OK': 'Oklahoma',
        'WY': 'Wyoming',
        'DE': 'Delaware',
        'AL': 'Alabama',
        'VV': 'North Holland',      # Netherlands (1)
        'NSW': 'New South Wales',   # Australia (1)
        'SU': 'Sutherland',
        'ST': 'Stirling',
        'RO': 'Roxburgh',
        # 'FL': 'Flintshire',         # Clash with US
        'AG': 'Anglesey',
        'YK': 'Yorkshire',
        'SH': 'Shetland',
        'KR': 'Kinross',
        'GL': 'Gloucestershire'
    })

    # Expand overlapping codes
    # FL is defined for both US (Florida) and UK (Flintshire)
    # IL is defined for both US (Illinois) and France (Ile-de-France)
    def expand_state_codes_with_overlap(df: pd.DataFrame, state_code_map: List[Tuple[str, str, str]]):
        df_copy = df.copy()
        for country, state, full in state_code_map:
            df_copy.loc[df_copy[(df_copy['Country'] == country) & (
                df_copy['State'] == state)].index, 'State'] = full
        return df_copy

    df = expand_state_codes_with_overlap(
        df=df,
        state_code_map=[
            ('United States', 'FL', 'Florida'),
            ('United States', 'IL', 'Illinois'),
            ('France', 'IL', '\xcele-de-France'),
            ('United Kingdom', 'FL', 'Flintshire')
        ])

    # Attach calling codes for phone numbers without
    # Calling codes are based on the Country column
    def attach_calling_codes(df: pd.DataFrame, calling_codes: Dict[str, int]):
        df_copy = df.copy()
        for i in df_copy[~df_copy['Phone'].str.contains('+', regex=False, na=True)].index:
            phone = df_copy.loc[i, 'Phone']
            country = df_copy.loc[i, 'Country']
            df_copy.loc[i, 'Phone'] = '+' + \
                str(calling_codes[country]) + ' ' + phone
        return df_copy

    df = attach_calling_codes(
        df=df,
        calling_codes={
            'Canada': 1,
            'Italy': 39,
            'United States': 1,
            'France': 33,
            'United Kingdom': 44
        })

    # Change data type of SupportRepId from string to integer
    df['SupportRepId'] = df['SupportRepId'].astype(int)

    # Save cleaned data as a new csv file
    df.to_csv(
        path_or_buf=out,
        sep=';',
        encoding='utf-16')


OUTPUT_FILE = './CleanCustomer.csv'

clean_customer_csv(OUTPUT_FILE)

# Check data
new_df = pd.read_csv(
    filepath_or_buffer=OUTPUT_FILE,
    sep=';',
    index_col=0,
    encoding='utf-16'
)

print(new_df.head())
