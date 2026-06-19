import styles from "./Example.module.css";

interface Props {
    text: string;
    value: string;
    onClick: (value: string) => void;
    isSelected?: boolean;
}

export const Example = ({ text, value, onClick, isSelected }: Props) => {
    return (
        <div className={styles.example} onClick={() => onClick(value)} style={{ background: isSelected ? 'white' : '', boxShadow: isSelected ? '0px 4px 4px 0px rgba(0, 0, 0, 0.10)' : '', border : isSelected ? 'transparent' : '' }}>
        <p className={styles.exampleText} >{text}</p>
    </div>
    );
};
