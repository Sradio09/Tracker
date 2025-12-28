import UIKit

extension CreateTrackerViewController: UICollectionViewDelegate {
    
    // MARK: - Layout
    
    func makeCollectionLayout() -> UICollectionViewLayout {
        UICollectionViewCompositionalLayout { _, _ in
            let side: CGFloat = 52
            let columns = 6
            
            let itemSize = NSCollectionLayoutSize(
                widthDimension: .absolute(side),
                heightDimension: .absolute(side)
            )
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            
            let groupSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .absolute(side)
            )
            
            let group = NSCollectionLayoutGroup.horizontal(
                layoutSize: groupSize,
                repeatingSubitem: item,
                count: columns
            )
            group.interItemSpacing = .fixed(8)
            
            let section = NSCollectionLayoutSection(group: group)
            section.interGroupSpacing = 12
            section.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 0, bottom: 24, trailing: 0)
            
            let headerSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .absolute(28)
            )
            let header = NSCollectionLayoutBoundarySupplementaryItem(
                layoutSize: headerSize,
                elementKind: UICollectionView.elementKindSectionHeader,
                alignment: .top
            )
            section.boundarySupplementaryItems = [header]
            
            return section
        }
    }
    
    // MARK: - DataSource
    
    func setupCollectionDataSource() {
        dataSource = UICollectionViewDiffableDataSource<Section, Item>(
            collectionView: selectionCollectionView
        ) { collectionView, indexPath, item in
            switch item {
            case .emoji(let value):
                let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: EmojiCell.reuseId,
                    for: indexPath
                ) as! EmojiCell
                cell.configure(emoji: value)
                return cell
                
            case .color(let color):
                let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: ColorCell.reuseId,
                    for: indexPath
                ) as! ColorCell
                cell.configure(color: color)
                return cell
            }
        }
        
        dataSource.supplementaryViewProvider = { collectionView, kind, indexPath in
            guard kind == UICollectionView.elementKindSectionHeader else { return nil }
            
            let header = collectionView.dequeueReusableSupplementaryView(
                ofKind: kind,
                withReuseIdentifier: SectionHeaderView.reuseId,
                for: indexPath
            ) as! SectionHeaderView
            
            let section = Section(rawValue: indexPath.section)!
            header.configure(title: section.title)
            return header
        }
    }
    
    func applyCollectionSnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections(Section.allCases)
        snapshot.appendItems(emojis.map { .emoji($0) }, toSection: .emoji)
        snapshot.appendItems(colors.map { .color($0) }, toSection: .color)
        
        dataSource.apply(snapshot, animatingDifferences: false) { [weak self] in
            self?.updateSelectionCollectionHeight()
            self?.view.layoutIfNeeded()
        }
    }
    
    // MARK: - Selection (без reloadItems / snapshot — чтобы не было крэшей)
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let item = dataSource.itemIdentifier(for: indexPath),
              let section = Section(rawValue: indexPath.section) else { return }
        
        switch (section, item) {
        case (.emoji, .emoji(let value)):
            if let prev = selectedEmojiIndexPath, prev != indexPath {
                collectionView.deselectItem(at: prev, animated: false)
            }
            selectedEmojiIndexPath = indexPath
            selectedEmoji = value
            
        case (.color, .color(let color)):
            if let prev = selectedColorIndexPath, prev != indexPath {
                collectionView.deselectItem(at: prev, animated: false)
            }
            selectedColorIndexPath = indexPath
            selectedColor = color
            
        default:
            break
        }
        
        validate()
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
    }
    
    // MARK: - Auto height
    
    func updateSelectionCollectionHeight() {
        selectionCollectionView.layoutIfNeeded()
        let height = selectionCollectionView.collectionViewLayout.collectionViewContentSize.height
        guard height > 1 else { return }
        
        if selectionCollectionHeightConstraint?.constant != height {
            selectionCollectionHeightConstraint?.constant = height
        }
    }
}

